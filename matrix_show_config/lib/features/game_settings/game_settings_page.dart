import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../services/panel_service.dart';

class GameSettingsPage extends StatefulWidget {
  const GameSettingsPage({super.key, required this.service, required this.connected, required this.gameState});
  final PanelService service;
  final RxBool connected;
  final RxString gameState;
  @override
  State<GameSettingsPage> createState() => _GameSettingsPageState();
}

class _GameSettingsPageState extends State<GameSettingsPage> {
  final form=GlobalKey<FormState>();
  final target=TextEditingController(), margin=TextEditingController(), easy=TextEditingController(),
      hard=TextEditingController(), speed=TextEditingController();
  bool busy=false, loaded=false;
  String? feedback;
  bool success=false;

  @override
  void initState(){super.initState(); _load();}
  @override
  void dispose(){for(final c in [target,margin,easy,hard,speed]) {c.dispose();} super.dispose();}

  void _populate(PanelConfig c) {
    final mm=c.targetCs~/6000, ss=(c.targetCs~/100)%60, cs=c.targetCs%100;
    String two(int n)=>n.toString().padLeft(2,'0');
    target.text='${two(mm)}:${two(ss)}.${two(cs)}';
    margin.text='${c.marginCs}'; easy.text=c.easyRgb.toRadixString(16).padLeft(6,'0').toUpperCase();
    hard.text=c.hardRgb.toRadixString(16).padLeft(6,'0').toUpperCase(); speed.text='${c.traversalMs}';
  }
  String _err(Object e, {bool saving=false}) {
    if(saving && (e is TimeoutException || (e is PanelException && e.code=='disconnected'))) return 'game_uncertain'.tr;
    if(e is PanelException && e.code=='game_busy') return 'game_busy'.tr;
    if(e is PanelException && e.code=='storage_error') return 'game_storage_error'.tr;
    return 'game_error'.tr;
  }
  Future<void> _load() async {
    if(busy) return;
    if(!widget.connected.value){setState(() {feedback='game_offline'.tr; success=false;});return;}
    setState((){busy=true;feedback=null;});
    try {
      final config=await widget.service.getConfig();
      if(!mounted)return;
      setState((){_populate(config);loaded=true;feedback='game_loaded'.tr;success=true;});
    } catch(e) {if(mounted) setState((){feedback=_err(e);success=false;});}
    finally {if(mounted)setState(()=>busy=false);}
  }
  int? _parseTime(String input) {
    final match=RegExp(r'^(\d{2}):(\d{2})\.(\d{2})$').firstMatch(input);
    if(match==null)return null;
    final m=int.parse(match[1]!),s=int.parse(match[2]!),c=int.parse(match[3]!);
    if(s>59)return null;
    return m*6000+s*100+c;
  }
  String? _validateInt(String? s,int min,int max) {
    if(s==null || !RegExp(r'^\d+$').hasMatch(s))return 'game_invalid'.tr;
    final v=int.tryParse(s);
    return v==null || v<min || v>max ? 'game_invalid'.tr : null;
  }
  String? _validateRgb(String? s) => s==null || !RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(s) ? 'game_hex_hint'.tr : null;
  Future<void> _save() async {
    if(busy || !loaded || !widget.connected.value || widget.gameState.value!='pret') return;
    if(!(form.currentState?.validate()??false))return;
    final config=PanelConfig(targetCs:_parseTime(target.text)!,marginCs:int.parse(margin.text),
        easyRgb:int.parse(easy.text,radix:16),hardRgb:int.parse(hard.text,radix:16),traversalMs:int.parse(speed.text));
    setState((){busy=true;feedback=null;success=false;});
    try {
      final confirmed=await widget.service.setConfig(config);
      if(!mounted)return;
      if(jsonEncode(confirmed.toJson())!=jsonEncode(config.toJson())) {
        setState((){feedback='game_mismatch'.tr;loaded=false;});return;
      }
      setState((){_populate(confirmed);feedback='game_saved'.tr;success=true;});
    } catch(e) {
      if(mounted) setState((){feedback=_err(e,saving:true);success=false;
      if(e is TimeoutException || (e is PanelException && e.code=='disconnected')) loaded=false;});
    } finally {if(mounted)setState(()=>busy=false);}
  }
  Widget _rgbField(TextEditingController controller,String label) => Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    TextFormField(controller:controller,decoration:InputDecoration(labelText:label,prefixText:'#',helperText:'game_hex_hint'.tr),
        maxLength:6,inputFormatters:[FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]'))],validator:_validateRgb,
        onChanged:(_)=>setState((){})),
    Wrap(spacing:8,children:[0x00ff00,0xff0000,0x0000ff,0xffffff,0xffa500].map((rgb)=>
        ActionChip(label:Text('#${rgb.toRadixString(16).padLeft(6,'0').toUpperCase()}'),
            avatar:CircleAvatar(backgroundColor:Color(0xff000000|rgb)),
            onPressed:busy?null:()=>setState(()=>controller.text=rgb.toRadixString(16).padLeft(6,'0').toUpperCase()))).toList()),
  ]);
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar:AppBar(title:Text('game_settings'.tr)),
      body:SafeArea(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:720),
          child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Obx(() {
            final connected=widget.connected.value, ready=widget.gameState.value=='pret';
            return Form(key:form,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
              Text('game_instructions'.tr),const SizedBox(height:16),
              if(!connected) Text('game_offline'.tr) else if(!ready) Text('game_busy'.tr),
              if(busy) const LinearProgressIndicator(),
              const SizedBox(height:12),
              TextFormField(controller:target,enabled:loaded&&!busy,decoration:InputDecoration(labelText:'game_target'.tr,helperText:'game_time_help'.tr),
                  keyboardType:TextInputType.datetime,validator:(s)=>_parseTime(s??'')==null?'game_time_help'.tr:null),
              const SizedBox(height:16),
              TextFormField(controller:margin,enabled:loaded&&!busy,decoration:InputDecoration(labelText:'game_margin'.tr,helperText:'game_margin_help'.tr),
                  keyboardType:TextInputType.number,validator:(s)=>_validateInt(s,0,599999)),
              const SizedBox(height:16),
              IgnorePointer(ignoring:!loaded||busy,child:Opacity(opacity:loaded?1:0.5,child:_rgbField(easy,'game_easy'.tr))),
              const SizedBox(height:16),
              IgnorePointer(ignoring:!loaded||busy,child:Opacity(opacity:loaded?1:0.5,child:_rgbField(hard,'game_hard'.tr))),
              const SizedBox(height:16),
              TextFormField(controller:speed,enabled:loaded&&!busy,decoration:InputDecoration(labelText:'game_speed'.tr,helperText:'game_speed_help'.tr),
                  keyboardType:TextInputType.number,validator:(s)=>_validateInt(s,100,60000)),
              const SizedBox(height:20),
              FilledButton(onPressed:connected&&ready&&loaded&&!busy?_save:null,child:Text('game_apply'.tr)),
              OutlinedButton(onPressed:connected&&!busy?_load:null,child:Text('game_reload'.tr)),
              if(feedback!=null) Padding(padding:const EdgeInsets.only(top:12),child:Text(feedback!,style:TextStyle(
                  color:success?Theme.of(context).colorScheme.primary:Theme.of(context).colorScheme.error))),
            ]));
          }))))));
}