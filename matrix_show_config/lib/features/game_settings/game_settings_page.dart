import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import '../../services/panel_service.dart';

class GameSettingsPage extends StatefulWidget {
  const GameSettingsPage({
    super.key,
    required this.service,
    required this.connected,
    required this.gameState,
  });
  final PanelService service;
  final RxBool connected;
  final RxString gameState;
  @override
  State<GameSettingsPage> createState() => _GameSettingsPageState();
}

class _GameSettingsPageState extends State<GameSettingsPage> {
  final form = GlobalKey<FormState>();
  final target = TextEditingController(),
      margin = TextEditingController(),
      speed = TextEditingController();
  int easyRgb = 0x00ff00, hardRgb = 0xff0000;
  bool busy = false, loaded = false;
  String? feedback;
  bool success = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [target, margin, speed]) {
      c.dispose();
    }
    super.dispose();
  }

  void _populate(PanelConfig c) {
    final mm = c.targetCs ~/ 6000,
        ss = (c.targetCs ~/ 100) % 60,
        cs = c.targetCs % 100;
    String two(int n) => n.toString().padLeft(2, '0');
    target.text = '${two(mm)}:${two(ss)}.${two(cs)}';
    margin.text = '${c.marginCs}';
    easyRgb = c.easyRgb;
    hardRgb = c.hardRgb;
    speed.text = '${c.traversalMs}';
  }

  String _err(Object e, {bool saving = false}) {
    if (saving &&
        (e is TimeoutException ||
            (e is PanelException && e.code == 'disconnected')))
      return 'game_uncertain'.tr;
    if (e is PanelException && e.code == 'game_busy') return 'game_busy'.tr;
    if (e is PanelException && e.code == 'storage_error')
      return 'game_storage_error'.tr;
    return 'game_error'.tr;
  }

  Future<void> _load() async {
    if (busy) return;
    if (!widget.connected.value) {
      setState(() {
        feedback = 'game_offline'.tr;
        success = false;
      });
      return;
    }
    setState(() {
      busy = true;
      feedback = null;
    });
    try {
      final config = await widget.service.getConfig();
      if (!mounted) return;
      setState(() {
        _populate(config);
        loaded = true;
        feedback = 'game_loaded'.tr;
        success = true;
      });
    } catch (e) {
      if (mounted)
        setState(() {
          feedback = _err(e);
          success = false;
        });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  int? _parseTime(String input) {
    final match = RegExp(r'^(\d{2}):(\d{2})\.(\d{2})$').firstMatch(input);
    if (match == null) return null;
    final m = int.parse(match[1]!),
        s = int.parse(match[2]!),
        c = int.parse(match[3]!);
    if (s > 59) return null;
    return m * 6000 + s * 100 + c;
  }

  String? _validateInt(String? s, int min, int max) {
    if (s == null || !RegExp(r'^\d+$').hasMatch(s)) return 'game_invalid'.tr;
    final v = int.tryParse(s);
    return v == null || v < min || v > max ? 'game_invalid'.tr : null;
  }

  Future<void> _save() async {
    if (busy ||
        !loaded ||
        !widget.connected.value ||
        widget.gameState.value != 'pret')
      return;
    if (!(form.currentState?.validate() ?? false)) return;
    final config = PanelConfig(
      targetCs: _parseTime(target.text)!,
      marginCs: int.parse(margin.text),
      easyRgb: easyRgb,
      hardRgb: hardRgb,
      traversalMs: int.parse(speed.text),
    );
    setState(() {
      busy = true;
      feedback = null;
      success = false;
    });
    try {
      final confirmed = await widget.service.setConfig(config);
      if (!mounted) return;
      if (jsonEncode(confirmed.toJson()) != jsonEncode(config.toJson())) {
        setState(() {
          feedback = 'game_mismatch'.tr;
          loaded = false;
        });
        return;
      }
      setState(() {
        _populate(confirmed);
        feedback = 'game_saved'.tr;
        success = true;
      });
    } catch (e) {
      if (mounted)
        setState(() {
          feedback = _err(e, saving: true);
          success = false;
          if (e is TimeoutException ||
              (e is PanelException && e.code == 'disconnected'))
            loaded = false;
        });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _setRgb(bool isEasy, int value) {
    setState(() {
      if (isEasy) {
        easyRgb = value;
      } else {
        hardRgb = value;
      }
      feedback = null;
      success = false;
    });
  }

  Future<void> _chooseCustom(bool isEasy) async {
    Color selected = Color(0xff000000 | (isEasy ? easyRgb : hardRgb));
    final result = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('game_custom_color'.tr),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: selected,
            onColorChanged: (color) {
              selected = color;
            },
            paletteType: PaletteType.hueWheel,
            enableAlpha: false,
            labelTypes: const [],
            hexInputBar: false,
            colorPickerWidth: 260,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('game_cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, selected),
            child: Text('game_choose'.tr),
          ),
        ],
      ),
    );
    if (!mounted || result == null) return;
    _setRgb(isEasy, result.toARGB32() & 0x00ffffff);
  }

  Widget _colorField(bool isEasy, String label) {
    final current = isEasy ? easyRgb : hardRgb;
    const presets = [0x00ff00, 0xff0000, 0x0000ff, 0xffffff, 0xffa500];
    const names = [
      'color_green',
      'color_red',
      'color_blue',
      'color_white',
      'color_orange',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Semantics(
          label: 'game_selected_color'.tr,
          child: Container(
            height: 48,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xff000000 | current),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 0; i < presets.length; i++)
              Semantics(
                label: names[i].tr,
                selected: current == presets[i],
                button: true,
                child: Tooltip(
                  message: names[i].tr,
                  child: InkWell(
                    onTap: () => _setRgb(isEasy, presets[i]),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xff000000 | presets[i]),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: current == presets[i]
                          ? Icon(
                              Icons.check,
                              color:
                                  Color(
                                        0xff000000 | presets[i],
                                      ).computeLuminance() >
                                      0.4
                                  ? Colors.black
                                  : Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            OutlinedButton.icon(
              onPressed: () => _chooseCustom(isEasy),
              icon: const Icon(Icons.palette_outlined),
              label: Text('game_custom_color'.tr),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('game_settings'.tr)),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Obx(() {
              final connected = widget.connected.value;
              final ready = widget.gameState.value == 'pret';
              final theme = Theme.of(context);
              void clearFeedback(String _) {
                if (feedback != null)
                  setState(() {
                    feedback = null;
                    success = false;
                  });
              }

              Widget section(Widget child) => Card(
                margin: EdgeInsets.zero,
                child: Padding(padding: const EdgeInsets.all(16), child: child),
              );
              return Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'game_settings'.tr,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'game_instructions'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!connected)
                      Text('game_offline'.tr)
                    else if (!ready)
                      Text('game_busy'.tr),
                    if (busy) const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                    section(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'game_target'.tr,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: target,
                            enabled: loaded && !busy,
                            decoration: InputDecoration(
                              labelText: 'game_target'.tr,
                              helperText: 'game_time_help'.tr,
                            ),
                            onChanged: clearFeedback,
                            keyboardType: TextInputType.datetime,
                            validator: (s) => _parseTime(s ?? '') == null
                                ? 'game_time_help'.tr
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: margin,
                            enabled: loaded && !busy,
                            decoration: InputDecoration(
                              labelText: 'game_margin'.tr,
                              helperText: 'game_margin_help'.tr,
                            ),
                            onChanged: clearFeedback,
                            keyboardType: TextInputType.number,
                            validator: (s) => _validateInt(s, 0, 599999),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    section(
                      IgnorePointer(
                        ignoring: !loaded || busy,
                        child: Opacity(
                          opacity: loaded ? 1 : 0.5,
                          child: _colorField(true, 'game_easy'.tr),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    section(
                      IgnorePointer(
                        ignoring: !loaded || busy,
                        child: Opacity(
                          opacity: loaded ? 1 : 0.5,
                          child: _colorField(false, 'game_hard'.tr),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    section(
                      TextFormField(
                        controller: speed,
                        enabled: loaded && !busy,
                        decoration: InputDecoration(
                          labelText: 'game_speed'.tr,
                          helperText: 'game_speed_help'.tr,
                        ),
                        onChanged: clearFeedback,
                        keyboardType: TextInputType.number,
                        validator: (s) => _validateInt(s, 100, 60000),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: connected && ready && loaded && !busy
                          ? _save
                          : null,
                      child: Text('game_apply'.tr),
                    ),
                    OutlinedButton(
                      onPressed: connected && !busy ? _load : null,
                      child: Text('game_reload'.tr),
                    ),
                    if (feedback != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          feedback!,
                          style: TextStyle(
                            color: success
                                ? theme.colorScheme.primary
                                : theme.colorScheme.error,
                          ),
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
