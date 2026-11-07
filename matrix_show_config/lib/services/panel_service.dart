import 'dart:async';
import 'dart:convert';
import 'dart:io';

class PanelStatus {
  const PanelStatus({required this.mode, required this.state});
  final String mode;
  final String state;
}

class PanelConfig {
  const PanelConfig({required this.targetCs, required this.marginCs,
    required this.easyRgb, required this.hardRgb, required this.traversalMs});
  final int targetCs, marginCs, easyRgb, hardRgb, traversalMs;

  Map<String, int> toJson() => {'cible_cs':targetCs, 'marge_cs':marginCs,
    'facile_rgb':easyRgb, 'difficile_rgb':hardRgb, 'traversee_ms':traversalMs};

  factory PanelConfig.fromJson(Map<String, dynamic> data) {
    int field(String name, int min, int max) {
      final value = data[name];
      if (value is! int || value < min || value > max) throw const FormatException('invalid_response');
      return value;
    }
    return PanelConfig(targetCs:field('cible_cs',0,599999), marginCs:field('marge_cs',0,599999),
        easyRgb:field('facile_rgb',0,0xffffff), hardRgb:field('difficile_rgb',0,0xffffff),
        traversalMs:field('traversee_ms',100,60000));
  }
}

class PanelException implements Exception {
  const PanelException(this.code);
  final String code;
}

class PanelService {
  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  Timer? _refresh;
  final _pending = <String, Completer<Map<String, dynamic>>>{};
  int _nextId = 0;

  void _failPending() {
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(const PanelException('disconnected'));
    }
    _pending.clear();
  }

  Future<void> close() async {
    _refresh?.cancel(); _refresh = null;
    _failPending();
    await _subscription?.cancel(); _subscription = null;
    await _socket?.close(); _socket = null;
  }

  Future<void> connect(String host, {required void Function(PanelStatus) onStatus,
    required void Function() onDisconnected}) async {
    final addr=InternetAddress.tryParse(host);
    if(addr==null || addr.type!=InternetAddressType.IPv4) throw const FormatException('invalid_ip');
    await close();
    final socket=await WebSocket.connect('ws://$host:81/').timeout(const Duration(seconds:5));
    _socket=socket;
    final first=Completer<void>();
    void disconnected() {
      _refresh?.cancel(); _failPending();
      if(!first.isCompleted) first.completeError(const PanelException('disconnected'));
      onDisconnected();
    }
    _subscription=socket.listen((message) {
      try {
        if(message is! String || message.length>4096) return;
        final value=jsonDecode(message);
        if(value is! Map<String,dynamic> || value['version']!=1) return;
        if(value['type']=='status' && value['mode'] is String && value['etat'] is String) {
          onStatus(PanelStatus(mode:value['mode'] as String,state:value['etat'] as String));
          if(!first.isCompleted) first.complete();
        }
        final id=value['id'];
        if(id is String) {
          final completer=_pending.remove(id);
          if(completer!=null && !completer.isCompleted) completer.complete(value);
        }
      } on FormatException { /* Ignore invalid frames. */ }
    }, onDone:disconnected, onError:(Object _) => disconnected());
    void requestStatus() {
      if(socket.readyState==WebSocket.open) socket.add(jsonEncode({'type':'get_status','id':'status'}));
    }
    requestStatus();
    try {
      await first.future.timeout(const Duration(seconds:5));
      _refresh=Timer.periodic(const Duration(seconds:3), (_) => requestStatus());
    } catch (_) { await close(); rethrow; }
  }

  Future<Map<String,dynamic>> _request(String type, {Map<String,int>? config}) async {
    final socket=_socket;
    if(socket==null || socket.readyState!=WebSocket.open) throw const PanelException('disconnected');
    final id='req${++_nextId}';
    final completer=Completer<Map<String,dynamic>>();
    _pending[id]=completer;
    try {
      socket.add(jsonEncode({'type':type,'id':id,if(config!=null) 'config':config}));
      final response=await completer.future.timeout(const Duration(seconds:5));
      if(response['type']=='error') throw PanelException(response['code'] is String ? response['code'] as String : 'unknown');
      return response;
    } finally { _pending.remove(id); }
  }

  Future<bool> advertisingAvailable() async {
    final response=await _request('get_capabilities');
    final features=response['features'];
    if(response['type']!='capabilities' || features is! Map || features['advertising'] is! bool) {
      throw const FormatException('invalid_response');
    }
    return features['advertising'] as bool;
  }

  Future<PanelConfig> getConfig() async {
    final response=await _request('get_config');
    if(response['type']!='config') throw const FormatException('invalid_response');
    return PanelConfig.fromJson(response);
  }
  Future<PanelConfig> setConfig(PanelConfig config) async {
    final response=await _request('set_config',config:config.toJson());
    if(response['type']!='config_applied') throw const FormatException('invalid_response');
    return PanelConfig.fromJson(response);
  }
}