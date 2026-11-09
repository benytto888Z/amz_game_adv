import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/panel_service.dart';
import '../../services/phone_clock.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({
    super.key,
    required this.service,
    required this.connected,
  });
  final PanelService service;
  final RxBool connected;
  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final first = TextEditingController(), last = TextEditingController();
  final start = TextEditingController(), end = TextEditingController();
  int days = 127;
  bool enabled = false, loaded = false, busy = false, ok = false;
  bool clockValid = false, backupAvailable = false, storageAvailable = false;
  String? message;
  String t(String fr, String en) => Get.locale?.languageCode == 'en' ? en : fr;
  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void dispose() {
    first.dispose();
    last.dispose();
    start.dispose();
    end.dispose();
    super.dispose();
  }

  String dateString(int d) =>
      '${d ~/ 10000}-${((d ~/ 100) % 100).toString().padLeft(2, '0')}-${(d % 100).toString().padLeft(2, '0')}';
  String timeString(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
  int? parseDate(String s) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) return null;
    final a = int.parse(s.substring(0, 4)),
        m = int.parse(s.substring(5, 7)),
        d = int.parse(s.substring(8, 10));
    if (a < 2000 || a > 2099) return null;
    final x = DateTime(a, m, d);
    if (x.year != a || x.month != m || x.day != d) return null;
    return a * 10000 + m * 100 + d;
  }

  int? parseTime(String s, {bool allowEnd = false}) {
    if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(s)) return null;
    final h = int.parse(s.substring(0, 2)), m = int.parse(s.substring(3, 5));
    if (allowEnd && h == 24 && m == 0) return 1440;
    if (h > 23 || m > 59) return null;
    return h * 60 + m;
  }

  bool valid(Map<String, dynamic> r) =>
      r['actif'] is bool &&
      r['debut_date'] is int &&
      r['fin_date'] is int &&
      r['debut_minute'] is int &&
      r['fin_minute'] is int &&
      r['jours'] is int &&
      r['horloge_valide'] is bool &&
      r['secours_disponible'] is bool &&
      r['stockage_disponible'] is bool;
  void apply(Map<String, dynamic> r) {
    first.text = dateString(r['debut_date'] as int);
    last.text = dateString(r['fin_date'] as int);
    start.text = timeString(r['debut_minute'] as int);
    end.text = timeString(r['fin_minute'] as int);
    days = r['jours'] as int;
    enabled = r['actif'] as bool;
    clockValid = r['horloge_valide'] as bool;
    backupAvailable = r['secours_disponible'] as bool;
    storageAvailable = r['stockage_disponible'] as bool;
    loaded = true;
  }

  String error(Object e, {bool write = false}) {
    if (write &&
        (e is TimeoutException ||
            e is FormatException ||
            e is PanelException && e.code == 'disconnected'))
      return t(
        'Confirmation perdue : résultat inconnu. Relisez le panneau.',
        'Confirmation lost: outcome unknown. Reload the panel.',
      );
    if (e is PanelException && e.code == 'schedule_requires_content')
      return t(
        'Sauvegardez un message de secours et ajoutez une playlist avant activation.',
        'Save a fallback message and add a playlist before enabling.',
      );
    if (e is PanelException && e.code == 'schedule_storage_uncertain')
      return t(
        'Sauvegarde non confirmée : état du stockage incertain.',
        'Save unconfirmed: storage state uncertain.',
      );
    return t(
      'Erreur ou réponse incompatible.',
      'Error or incompatible response.',
    );
  }

  Future<void> refresh() async {
    if (busy || !widget.connected.value) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final r = await widget.service.scheduleGet();
      if (!valid(r)) throw const FormatException();
      if (mounted)
        setState(() {
          apply(r);
          ok = true;
          message = t(
            'Réglages lus sur le panneau.',
            'Settings read from panel.',
          );
        });
    } catch (e) {
      if (mounted)
        setState(() {
          loaded = false;
          ok = false;
          message = error(e);
        });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> sync() async {
    if (busy || !widget.connected.value) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final data = await compute(phoneClockSnapshot, 0);
      await widget.service.synchronizeClock(data);
      if (mounted)
        setState(() {
          clockValid = true;
          ok = true;
          message = t(
            'Heure confirmée par le panneau.',
            'Clock confirmed by the panel.',
          );
        });
    } catch (e) {
      if (mounted)
        setState(() {
          clockValid = false;
          ok = false;
          message = error(e, write: true);
        });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (busy || !loaded || !storageAvailable || !widget.connected.value) return;
    final a = parseDate(first.text),
        b = parseDate(last.text),
        c = parseTime(start.text),
        d = parseTime(end.text, allowEnd: true);
    if (a == null ||
        b == null ||
        c == null ||
        d == null ||
        a > b ||
        c >= d ||
        days == 0) {
      setState(() {
        ok = false;
        message = t(
          'Vérifiez les dates, jours et horaires. La plage ne doit pas traverser minuit.',
          'Check dates, days and times. The interval cannot cross midnight.',
        );
      });
      return;
    }
    final data = <String, dynamic>{
      'actif': enabled,
      'debut_date': a,
      'fin_date': b,
      'debut_minute': c,
      'fin_minute': d,
      'jours': days,
    };
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final r = await widget.service.scheduleSet(data);
      if (!valid(r) || data.entries.any((e) => r[e.key] != e.value))
        throw const FormatException();
      if (mounted)
        setState(() {
          apply(r);
          ok = true;
          message = t(
            'Programmation confirmée par le panneau.',
            'Schedule confirmed by the panel.',
          );
        });
    } catch (e) {
      if (mounted)
        setState(() {
          ok = false;
          loaded = false;
          message = error(e, write: true);
        });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(t('Programmation', 'Schedule'))),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Obx(() {
              final online = widget.connected.value;
              final can = online && loaded && storageAvailable && !busy;
              final names = t('L,M,M,J,V,S,D', 'M,T,W,T,F,S,S').split(',');
              final theme = Theme.of(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t('DIFFUSION · PROGRAMMATION', 'PLAYBACK · SCHEDULE'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t('Programmation', 'Schedule'),
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(
                      'Une période de dates et un créneau par jour. La fin est exclue. Les créneaux ne traversent pas minuit.',
                      'One date range and one interval per day. The end is exclusive. Intervals cannot cross midnight.',
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                child: Icon(
                                  Icons.access_time,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  t('Heure et secours', 'Clock and fallback'),
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t(
                              'La programmation fonctionne seulement en mode Advertising. Sans heure fiable ou hors plage, le message sauvegardé sert de secours.',
                              'The schedule only runs in Advertising mode. If time is untrusted or outside the window, the saved message is the fallback.',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t(
                              'L’heure doit être resynchronisée après coupure, changement de fuseau ou expiration.',
                              'Time must be synchronized after power loss, timezone changes or expiration.',
                            ),
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            clockValid
                                ? t(
                                    'Dernière heure confirmée : valide au dernier relevé.',
                                    'Last confirmed clock: valid at last reading.',
                                  )
                                : t(
                                    'Heure non confirmée ou expirée.',
                                    'Clock unconfirmed or expired.',
                                  ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            backupAvailable
                                ? t(
                                    'Message de secours sauvegardé.',
                                    'Fallback message saved.',
                                  )
                                : t(
                                    'Aucun message de secours confirmé.',
                                    'No confirmed fallback message.',
                                  ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: online && !busy ? sync : null,
                            icon: const Icon(Icons.sync),
                            label: Text(
                              t(
                                'Synchroniser l’heure du téléphone',
                                'Synchronize phone time',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (busy) const LinearProgressIndicator(),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  t('Dates et horaires', 'Dates and times'),
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: first,
                            enabled: can,
                            decoration: InputDecoration(
                              labelText: t(
                                'Date de début AAAA-MM-JJ',
                                'Start date YYYY-MM-DD',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: last,
                            enabled: can,
                            decoration: InputDecoration(
                              labelText: t(
                                'Date de fin AAAA-MM-JJ',
                                'End date YYYY-MM-DD',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: start,
                            enabled: can,
                            decoration: InputDecoration(
                              labelText: t('Début HH:MM', 'Start HH:MM'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: end,
                            enabled: can,
                            decoration: InputDecoration(
                              labelText: t(
                                'Fin HH:MM, 24:00 accepté',
                                'End HH:MM, 24:00 accepted',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 4,
                            children: List.generate(
                              7,
                              (i) => FilterChip(
                                label: Text(names[i]),
                                selected: (days & (1 << i)) != 0,
                                onSelected: can
                                    ? (v) => setState(
                                        () => days = v
                                            ? days | (1 << i)
                                            : days & ~(1 << i),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          SwitchListTile(
                            value: enabled,
                            onChanged: can
                                ? (v) => setState(() => enabled = v)
                                : null,
                            title: Text(
                              t('Programmation activée', 'Schedule enabled'),
                            ),
                          ),
                          FilledButton(
                            onPressed: can ? save : null,
                            child: Text(
                              t(
                                'Enregistrer la programmation',
                                'Save schedule',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: online && !busy ? refresh : null,
                    child: Text(t('Relire le panneau', 'Reload panel')),
                  ),
                  if (message != null)
                    Text(
                      message!,
                      style: TextStyle(
                        color: ok
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    ),
  );
}
