import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import '../../services/panel_service.dart';
import '../../core/matrix/matrix_preview.dart';
import '../../core/matrix/pixel_icons.dart';
import 'product_price_editor.dart';

class _IconPainter extends CustomPainter {
  const _IconPainter(this.id, this.color);

  final int id;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final cell = size.width / 5;

    for (var y = 0; y < 5; y++) {
      for (var x = 0; x < 5; x++) {
        if ((pixelIcons[id][y] & (1 << (4 - x))) != 0) {
          canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell, cell),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IconPainter old) =>
      old.id != id || old.color != color;
}

class LiveAdPage extends StatefulWidget {
  const LiveAdPage({
    super.key,
    required this.service,
    required this.connected,
    required this.gameState,
    required this.displayMode,
  });

  final PanelService service;
  final RxBool connected;
  final RxString gameState;
  final RxString displayMode;

  @override
  State<LiveAdPage> createState() => _LiveAdPageState();
}

class _LiveAdPageState extends State<LiveAdPage> {
  final text = TextEditingController();
  final form = GlobalKey<FormState>();

  int rgb = 0x00ffff;
  int interval = 70;
  int brightness = 20;
  int iconId = 0;
  int effectId = 0;

  bool scroll = true;
  bool busy = false;
  bool loaded = false;
  bool success = false;
  bool dirty = false;

  String playback = 'stop';
  String? feedback;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  bool valid(Map<String, dynamic> r) =>
      r['texte'] is String &&
          r['couleur_rgb'] is int &&
          r['intervalle_ms'] is int &&
          r['luminosite'] is int &&
          r['scroll'] is bool &&
          r['lecture'] is String &&
          ['play', 'pause', 'stop'].contains(r['lecture']) &&
          r['icone'] is int &&
          (r['icone'] as int) >= 0 &&
          (r['icone'] as int) <= 3 &&
          r['effet'] is int &&
          (r['effet'] as int) >= 0 &&
          (r['effet'] as int) <= 2;

  void populate(Map<String, dynamic> r) {
    text.text = r['texte'] as String;
    rgb = r['couleur_rgb'] as int;
    interval = r['intervalle_ms'] as int;
    brightness = r['luminosite'] as int;
    scroll = r['scroll'] as bool;
    playback = r['lecture'] as String;
    iconId = r['icone'] as int;
    effectId = r['effet'] as int;
  }

  void changed() {
    setState(() {
      dirty = true;
      feedback = null;
      success = false;
    });
  }

  String errorText(Object e, {bool writing = false}) {
    if (writing &&
        (e is TimeoutException ||
            e is PanelException && e.code == 'disconnected')) {
      return 'live_unknown'.tr;
    }

    if (e is PanelException && e.code == 'firmware_effects') {
      return 'effects_firmware'.tr;
    }

    if (e is PanelException && e.code == 'firmware_storage') {
      return 'pub_store_firmware'.tr;
    }

    if (e is PanelException && e.code == 'ad_storage_unavailable') {
      return 'pub_store_unavailable'.tr;
    }

    if (e is PanelException && e.code == 'ad_storage_uncertain') {
      return 'pub_store_uncertain'.tr;
    }

    if (e is PanelException && e.code == 'schedule_active') return 'schedule_active'.tr;

    if (e is PanelException && e.code == 'not_advertising') {
      return 'display_required'.tr;
    }

    if (e is PanelException && e.code == 'game_busy') {
      return 'live_busy'.tr;
    }

    return 'live_error'.tr;
  }

  Future<void> load() async {
    if (busy) return;

    if (!widget.connected.value) {
      setState(() {
        feedback = 'live_offline'.tr;
        success = false;
      });
      return;
    }

    setState(() {
      busy = true;
      feedback = null;
    });

    try {
      final response = await widget.service.liveGet();

      if (!response.containsKey('icone') ||
          !response.containsKey('effet')) {
        throw const PanelException('firmware_effects');
      }

      if (response['stockage_disponible'] is! bool ||
          response['sauvegarde'] is! bool) {
        throw const PanelException('firmware_storage');
      }

      if (!valid(response)) {
        throw const FormatException('invalid_response');
      }

      if (!mounted) return;

      setState(() {
        populate(response);
        loaded = true;
        dirty = false;
        success = true;
        feedback = 'live_loaded'.tr;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          success = false;
          feedback = errorText(e);
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (busy ||
        !loaded ||
        !widget.connected.value ||
        widget.gameState.value != 'pret' ||
        widget.displayMode.value != 'advertising' ||
        !(form.currentState?.validate() ?? false)) {
      return;
    }

    final data = <String, dynamic>{
      'texte': text.text,
      'couleur_rgb': rgb,
      'intervalle_ms': interval,
      'luminosite': brightness,
      'scroll': scroll,
      'icone': iconId,
      'effet': effectId,
    };

    setState(() {
      busy = true;
      feedback = null;
      success = false;
    });

    try {
      final r = await widget.service.liveSet(data);

      if (!valid(r) ||
          r['texte'] != data['texte'] ||
          r['couleur_rgb'] != rgb ||
          r['intervalle_ms'] != interval ||
          r['luminosite'] != brightness ||
          r['scroll'] != scroll ||
          r['icone'] != iconId ||
          r['effet'] != effectId) {
        throw const FormatException('invalid_response');
      }

      if (!mounted) return;

      setState(() {
        populate(r);
        dirty = false;
        success = true;
        feedback = 'live_saved'.tr;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          feedback = errorText(e, writing: true);
          success = false;
          loaded = false;
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> action(String value) async {
    if (busy ||
        !loaded ||
        dirty ||
        !widget.connected.value ||
        widget.gameState.value != 'pret' ||
        widget.displayMode.value != 'advertising') {
      return;
    }

    setState(() {
      busy = true;
      feedback = null;
      success = false;
    });

    try {
      final r = await widget.service.liveAction(value);

      if (!valid(r) || r['lecture'] != value) {
        throw const FormatException('invalid_response');
      }

      if (!mounted) return;

      setState(() {
        playback = r['lecture'] as String;
        success = true;
        feedback = 'live_action_ok'.tr;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          success = false;
          feedback = errorText(e, writing: true);
          loaded = false;
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> saveForRestart() async {
    if (busy ||
        !loaded ||
        dirty ||
        !widget.connected.value ||
        widget.gameState.value != 'pret' ||
        widget.displayMode.value != 'advertising') {
      return;
    }

    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('pub_store_confirm_title'.tr),
        content: Text('pub_store_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('game_cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('pub_store_button'.tr),
          ),
        ],
      ),
    );

    if (!mounted ||
        yes != true ||
        busy ||
        !loaded ||
        dirty ||
        !widget.connected.value ||
        widget.gameState.value != 'pret' ||
        widget.displayMode.value != 'advertising') {
      return;
    }

    setState(() {
      busy = true;
      feedback = null;
      success = false;
    });

    try {
      final r = await widget.service.liveSave();

      if (!valid(r) ||
          r['sauvegarde'] != true ||
          r['texte'] != text.text ||
          r['couleur_rgb'] != rgb ||
          r['intervalle_ms'] != interval ||
          r['luminosite'] != brightness ||
          r['scroll'] != scroll ||
          r['icone'] != iconId ||
          r['effet'] != effectId) {
        throw const PanelException('ad_storage_uncertain');
      }

      if (mounted) {
        setState(() {
          success = true;
          feedback = 'pub_store_success'.tr;
        });

      }
    } catch (e) {
      if (mounted) {
        setState(() {
          success = false;
          feedback = errorText(e, writing: true);
          loaded = false;
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> chooseColor() async {
    Color selected = Color(0xff000000 | rgb);

    final result = await showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('live_color'.tr),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: selected,
            onColorChanged: (c) => selected = c,
            paletteType: PaletteType.hueWheel,
            enableAlpha: false,
            labelTypes: const [],
            hexInputBar: false,
            colorPickerWidth: 260,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('game_cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, selected),
            child: Text('game_choose'.tr),
          ),
        ],
      ),
    );

    if (!mounted || result == null) return;

    setState(() => rgb = result.toARGB32() & 0xffffff);
    changed();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('live_title'.tr)),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Obx(() {
              final online = widget.connected.value;
              final advertisingMode =
                  widget.displayMode.value == 'advertising';
              final ready =
                  widget.gameState.value == 'pret' && advertisingMode;
              final can = online && ready && loaded && !busy;

              return Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('live_warning'.tr),
                    const SizedBox(height: 12),

                    Text(
                      'preview_local'.tr,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),

                    MatrixPreview(
                      text: text.text,
                      rgb: rgb,
                      scrolling: scroll,
                      intervalMs: interval,
                      iconId: iconId,
                      effectId: effectId,
                    ),

                    const SizedBox(height: 8),
                    Text('preview_notice'.tr),
                    const SizedBox(height: 12),

                    if (!online)
                      Text('live_offline'.tr)
                    else if (!advertisingMode)
                      Text('display_required'.tr)
                    else if (!ready)
                        Text('live_busy'.tr),

                    if (busy) const LinearProgressIndicator(),

                    ProductPriceEditor(
                      enabled: loaded && !busy,
                      onPrepared: (message) {
                        text.text = message;
                        changed();
                      },
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: text,
                      enabled: loaded && !busy,
                      maxLength: 100,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[\x20-\x7E]'),
                        ),
                      ],
                      onChanged: (_) => changed(),
                      validator: (v) =>
                      v == null || v.isEmpty
                          ? 'live_required'.tr
                          : null,
                      decoration: InputDecoration(
                        labelText: 'live_text'.tr,
                        helperText: 'live_ascii'.tr,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Color(0xff000000 | rgb),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed:
                          loaded && !busy ? chooseColor : null,
                          child: Text('live_color'.tr),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Text('icons_title'.tr),

                    Wrap(
                      spacing: 8,
                      children: List.generate(
                        pixelIcons.length,
                            (i) => ChoiceChip(
                          avatar: i == 0
                              ? const Icon(Icons.block, size: 20)
                              : CustomPaint(
                            size: const Size(20, 20),
                            painter: _IconPainter(
                              i,
                              Theme.of(context)
                                  .colorScheme
                                  .onSurface,
                            ),
                          ),
                          label: Text(('icon_$i').tr),
                          selected: iconId == i,
                          showCheckmark: false,
                          onSelected: loaded && !busy
                              ? (_) {
                            iconId = i;
                            changed();
                          }
                              : null,
                        ),
                      ),
                    ),

                    Text('icons_note'.tr),
                    const SizedBox(height: 12),
                    Text('effects_title'.tr),

                    Wrap(
                      spacing: 8,
                      children: List.generate(
                        3,
                            (i) => ChoiceChip(
                          label: Text(('effect_$i').tr),
                          selected: effectId == i,
                          onSelected: loaded && !busy
                              ? (_) {
                            effectId = i;
                            changed();
                          }
                              : null,
                        ),
                      ),
                    ),

                    Text('effects_notice'.tr),
                    const SizedBox(height: 12),

                    Text('${'live_speed'.tr}: $interval ms'),

                    Slider(
                      value: interval
                          .toDouble()
                          .clamp(20, 500)
                          .toDouble(),
                      min: 20,
                      max: 500,
                      divisions: 48,
                      onChanged: loaded && !busy
                          ? (v) {
                        interval = v.round();
                        changed();
                      }
                          : null,
                    ),

                    Text('${'live_brightness'.tr}: $brightness / 20'),

                    Slider(
                      value: brightness
                          .toDouble()
                          .clamp(1, 20)
                          .toDouble(),
                      min: 1,
                      max: 20,
                      divisions: 19,
                      onChanged: loaded && !busy
                          ? (v) {
                        brightness = v.round();
                        changed();
                      }
                          : null,
                    ),

                    SwitchListTile(
                      value: scroll,
                      onChanged: loaded && !busy
                          ? (v) {
                        scroll = v;
                        changed();
                      }
                          : null,
                      title: Text('live_scroll'.tr),
                    ),

                    Text('live_static_note'.tr),
                    const SizedBox(height: 8),

                    Text(
                      '${'live_state'.tr}: ${('live_$playback').tr}',
                    ),

                    const SizedBox(height: 12),

                    FilledButton(
                      onPressed: can ? save : null,
                      child: Text('live_send'.tr),
                    ),

                    const SizedBox(height: 8),
                    Text('pub_store_note'.tr),

                    OutlinedButton(
                      onPressed:
                      can && !dirty ? saveForRestart : null,
                      child: Text('pub_store_button'.tr),
                    ),

                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: can && !dirty
                              ? () => action('play')
                              : null,
                          child: Text('live_play'.tr),
                        ),
                        OutlinedButton(
                          onPressed: can &&
                              !dirty &&
                              playback != 'stop'
                              ? () => action('pause')
                              : null,
                          child: Text('live_pause'.tr),
                        ),
                        OutlinedButton(
                          onPressed: can && !dirty
                              ? () => action('stop')
                              : null,
                          child: Text('live_stop'.tr),
                        ),
                      ],
                    ),

                    OutlinedButton(
                      onPressed: online && !busy ? load : null,
                      child: Text('live_reload'.tr),
                    ),

                    if (feedback != null)
                      Text(
                        feedback!,
                        style: TextStyle(
                          color: success
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    ),
  );
}