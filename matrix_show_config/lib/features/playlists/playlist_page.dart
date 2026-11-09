import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../services/panel_service.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({
    super.key,
    required this.service,
    required this.connected,
    required this.displayMode,
  });

  final PanelService service;
  final RxBool connected;
  final RxString displayMode;

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final duration = TextEditingController();

  bool busy = false;
  bool loaded = false;
  bool active = false;
  bool available = false;
  bool ok = false;

  List<String> messages = [];
  String? feedback;

  bool get fr => Get.locale?.languageCode != 'en';

  String t(String french, String english) => fr ? french : english;

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void dispose() {
    duration.dispose();
    super.dispose();
  }

  bool valid(Map<String, dynamic> r) {
    final m = r['messages'];
    final d = r['duree_s'];

    return m is List &&
        m.length <= 5 &&
        m.every((v) => v is String) &&
        d is int &&
        d >= 3 &&
        d <= 300 &&
        r['active'] is bool &&
        r['disponible'] is bool &&
        r['index'] is int;
  }

  void apply(Map<String, dynamic> r) {
    messages = List<String>.from(r['messages'] as List);
    duration.text = '${r['duree_s']}';
    active = r['active'] as bool;
    available = r['disponible'] as bool;
    loaded = true;
  }

  String error(Object e, {bool write = false}) {
    if (write &&
        (e is TimeoutException ||
            e is FormatException ||
            e is PanelException && e.code == 'disconnected')) {
      return t(
        'Confirmation perdue : résultat inconnu. '
            'Reconnectez-vous puis relisez la playlist.',
        'Confirmation lost: outcome unknown. '
            'Reconnect and reload the playlist.',
      );
    }

    if (e is PanelException) {
      switch (e.code) {
        case 'schedule_active':
          return t('Désactivez la programmation avant de modifier la playlist.', 'Disable the schedule before changing the playlist.');

        case 'playlist_full':
          return t(
            'La playlist contient déjà 5 messages.',
            'Playlist already contains 5 messages.',
          );

        case 'playlist_empty':
          return t(
            'La playlist est vide.',
            'Playlist is empty.',
          );

        case 'playlist_busy':
          return t(
            'Arrêtez la playlist avant de la modifier.',
            'Stop the playlist before editing it.',
          );

        case 'not_advertising':
          return t(
            'Sélectionnez Advertising dans le tableau de bord.',
            'Select Advertising on the dashboard.',
          );

        case 'playlist_storage':
          return t(
            'Stockage indisponible ou données invalides.',
            'Storage unavailable or data invalid.',
          );

        case 'playlist_uncertain':
          return t(
            'Écriture non confirmée : état du stockage incertain.',
            'Write not confirmed: storage outcome uncertain.',
          );
      }
    }

    return t(
      'Réponse invalide ou erreur de communication.',
      'Invalid response or communication error.',
    );
  }

  Future<void> reload() async {
    if (busy || !widget.connected.value) return;

    setState(() {
      busy = true;
      feedback = null;
    });

    try {
      final r = await widget.service.playlistGet();

      if (!valid(r)) {
        throw const FormatException();
      }

      if (mounted) {
        setState(() {
          apply(r);
          ok = true;
          feedback = t(
            'Playlist lue sur le panneau.',
            'Playlist read from panel.',
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loaded = false;
          ok = false;
          feedback = error(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> change(String cmd, {int? seconds}) async {
    if (busy ||
        !loaded ||
        !widget.connected.value ||
        widget.displayMode.value != 'advertising') {
      return;
    }

    setState(() {
      busy = true;
      feedback = null;
    });

    try {
      final r = await widget.service.playlistChange(
        cmd,
        durationSeconds: seconds,
      );

      if (!valid(r) ||
          (cmd == 'add' &&
              (r['messages'] as List).length != messages.length + 1) ||
          (cmd == 'clear' &&
              (r['messages'] as List).isNotEmpty) ||
          (cmd == 'start' && r['active'] != true) ||
          (cmd == 'stop' && r['active'] != false) ||
          (cmd == 'duration' && r['duree_s'] != seconds)) {
        throw const FormatException();
      }

      if (mounted) {
        setState(() {
          apply(r);
          ok = true;
          feedback = t(
            'Commande confirmée par le panneau.',
            'Command confirmed by the panel.',
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          ok = false;
          loaded = false;
          feedback = error(e, write: true);
        });
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> clear() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          t('Effacer la playlist ?', 'Clear the playlist?'),
        ),
        content: Text(
          t(
            'Tous les messages de la playlist seront effacés. '
                'Le message individuel sauvegardé reste intact.',
            'All playlist messages will be deleted. '
                'The individually saved message remains intact.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('Annuler', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('Effacer', 'Clear')),
          ),
        ],
      ),
    );

    if (mounted && yes == true) {
      await change('clear');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        t('Playlist publicitaire', 'Advertising playlist'),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Obx(() {
              final connected = widget.connected.value;
              final adv = widget.displayMode.value == 'advertising';
              final can =
                  connected && adv && loaded && available && !busy;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t('Playlist publicitaire', 'Advertising playlist'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(
                      'Jusqu’à 5 messages. Préparez et envoyez chaque '
                          'message dans Contrôle en direct avant de '
                          'l’ajouter. La durée est commune.',
                      'Up to 5 messages. Prepare and send each message '
                          'in Live control before adding it. '
                          'All share the same duration.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(
                      'La playlist est conservée après coupure. Après '
                          'redémarrage, le panneau reste en Game. En mode '
                          'Advertising, elle peut être lancée manuellement '
                          'ou par une programmation activée.',
                      'The playlist is retained after power loss. After '
                          'restart, the panel remains in Game. In Advertising '
                          'mode it can be started manually or by an enabled schedule.',
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (!connected)
                    Text(
                      t('Panneau déconnecté.', 'Panel disconnected.'),
                    )
                  else if (!adv)
                    Text(
                      t(
                        'Sélectionnez Advertising dans le tableau de bord.',
                        'Select Advertising on the dashboard.',
                      ),
                    ),

                  if (busy) const LinearProgressIndicator(),

                  const SizedBox(height: 12),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(children: [
                            Icon(Icons.queue_music,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(child: Text(
                              t('Messages de la playlist', 'Playlist messages'),
                              style: Theme.of(context).textTheme.titleMedium,
                            )),
                            Text(loaded ? '${messages.length} / 5' : '— / 5',
                                style: Theme.of(context).textTheme.labelMedium),
                          ]),
                          const SizedBox(height: 8),
                          Text(
                            loaded
                                ? '${t('Dernier état lu :', 'Last read state:')} '
                                '${active ? t('en lecture', 'playing') : t('arrêtée', 'stopped')}'
                                : t('État non confirmé.', 'State not confirmed.'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (loaded && !available)
                            Text(t('Stockage indisponible ou données invalides.',
                                'Storage unavailable or invalid data.')),
                          if (loaded && messages.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(t('Aucun message.', 'No messages.')),
                            ),
                          if (loaded)
                            for (int i = 0; i < messages.length; i++)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(child: Text('${i + 1}')),
                                title: Text(messages[i]),
                              ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: duration,
                    enabled: can && !active,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: InputDecoration(
                      labelText: t(
                        'Durée commune en secondes (3–300)',
                        'Common duration in seconds (3–300)',
                      ),
                    ),
                  ),

                  OutlinedButton(
                    onPressed: can && !active
                        ? () {
                      final n = int.tryParse(duration.text);

                      if (n == null || n < 3 || n > 300) {
                        setState(() {
                          ok = false;
                          feedback = t(
                            'Durée invalide : entre 3 et 300 secondes.',
                            'Invalid duration: use 3 to 300 seconds.',
                          );
                        });
                        return;
                      }

                      change('duration', seconds: n);
                    }
                        : null,
                    child: Text(
                      t('Enregistrer la durée', 'Save duration'),
                    ),
                  ),

                  OutlinedButton(
                    onPressed: can && !active && messages.length < 5
                        ? () => change('add')
                        : null,
                    child: Text(
                      t(
                        'Ajouter le message actuel',
                        'Add current message',
                      ),
                    ),
                  ),

                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed:
                        can && !active && messages.isNotEmpty
                            ? () => change('start')
                            : null,
                        child: Text(t('Démarrer', 'Start')),
                      ),
                      OutlinedButton(
                        onPressed: can && active
                            ? () => change('stop')
                            : null,
                        child: Text(t('Arrêter', 'Stop')),
                      ),
                      OutlinedButton(
                        onPressed:
                        can && !active && messages.isNotEmpty
                            ? clear
                            : null,
                        child: Text(t('Tout effacer', 'Clear all')),
                      ),
                    ],
                  ),

                  OutlinedButton(
                    onPressed: connected && !busy ? reload : null,
                    child: Text(
                      t('Relire la playlist', 'Reload playlist'),
                    ),
                  ),

                  if (feedback != null)
                    Text(
                      feedback!,
                      style: TextStyle(
                        color: ok
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.error,
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