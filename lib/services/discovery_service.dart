import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../models/peer.dart';

/// Находит другие устройства в той же Wi-Fi сети через широковещательные UDP-пакеты.
class DiscoveryService {
  static const int discoveryPort = 45678;
  static const Duration broadcastInterval = Duration(seconds: 2);
  static const Duration peerTimeout = Duration(seconds: 8);

  final String myName;
  final int chatPort;
  final String sessionId = Random().nextInt(1 << 32).toString();

  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  Timer? _cleanupTimer;

  final _peers = <String, Peer>{}; // ключ — sessionId устройства
  final _peersController = StreamController<List<Peer>>.broadcast();

  Stream<List<Peer>> get peersStream => _peersController.stream;

  DiscoveryService({required this.myName, required this.chatPort});

  Future<void> start() async {
    _socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      discoveryPort,
      reuseAddress: true,
      reusePort: true,
    );
    _socket!.broadcastEnabled = true;

    _socket!.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = _socket!.receive();
        if (datagram != null) _handleIncoming(datagram);
      }
    });

    _broadcastTimer = Timer.periodic(broadcastInterval, (_) => _sendBroadcast());
    _cleanupTimer = Timer.periodic(const Duration(seconds: 3), (_) => _cleanupStale());

    _sendBroadcast();
  }

  void _sendBroadcast() {
    final payload = jsonEncode({
      'type': 'hello',
      'id': sessionId,
      'name': myName,
      'port': chatPort,
    });
    final data = utf8.encode(payload);
    try {
      _socket?.send(data, InternetAddress('255.255.255.255'), discoveryPort);
    } catch (_) {
      // широковещательный адрес недоступен — попробуем на следующем тике
    }
  }

  void _handleIncoming(Datagram datagram) {
    try {
      final msg = jsonDecode(utf8.decode(datagram.data)) as Map<String, dynamic>;
      if (msg['type'] != 'hello') return;

      final id = msg['id'] as String;
      if (id == sessionId) return; // это наш же пакет

      _peers[id] = Peer(
        id: id,
        name: msg['name'] as String,
        ip: datagram.address.address,
        port: msg['port'] as int,
        lastSeen: DateTime.now(),
      );
      _emit();
    } catch (_) {
      // битый/чужой пакет — игнорируем
    }
  }

  void _cleanupStale() {
    final now = DateTime.now();
    final before = _peers.length;
    _peers.removeWhere((_, p) => now.difference(p.lastSeen) > peerTimeout);
    if (_peers.length != before) _emit();
  }

  void _emit() => _peersController.add(_peers.values.toList());

  void stop() {
    _broadcastTimer?.cancel();
    _cleanupTimer?.cancel();
    _socket?.close();
    _peersController.close();
  }
}
