import 'dart:async';
import 'package:flutter/material.dart';

import '../models/peer.dart';
import '../services/discovery_service.dart';
import '../services/chat_network.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int chatPort = 5001;

  final _nameController = TextEditingController(text: 'Гость${DateTime.now().millisecond}');
  DiscoveryService? _discovery;
  ChatServer? _server;

  List<Peer> _peers = [];
  StreamSubscription? _peersSub;
  StreamSubscription? _incomingSub;
  bool _started = false;

  @override
  void dispose() {
    _peersSub?.cancel();
    _incomingSub?.cancel();
    _discovery?.stop();
    _server?.stop();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _startNetworking() async {
    final name = _nameController.text.trim().isEmpty
        ? 'Без имени'
        : _nameController.text.trim();

    _server = ChatServer(port: chatPort);
    await _server!.start();
    _incomingSub = _server!.incomingConnections.listen(_openIncomingChat);

    _discovery = DiscoveryService(myName: name, chatPort: chatPort);
    await _discovery!.start();
    _peersSub = _discovery!.peersStream.listen((peers) {
      setState(() => _peers = peers);
    });

    setState(() => _started = true);
  }

  void _openIncomingChat(ChatConnection conn) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatScreen(
        connection: conn,
        myName: _nameController.text.trim(),
        peerLabel: conn.remoteName,
      ),
    ));
  }

  Future<void> _openChatWith(Peer peer) async {
    try {
      final conn = await ChatServer.connectTo(peer.ip, peer.port, remoteName: peer.name);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatScreen(
          connection: conn,
          myName: _nameController.text.trim(),
          peerLabel: peer.name,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось подключиться: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LAN Чат')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              enabled: !_started,
              decoration: const InputDecoration(
                labelText: 'Ваше имя',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (!_started)
              ElevatedButton(
                onPressed: _startNetworking,
                child: const Text('Начать поиск в сети'),
              ),
            if (_started) ...[
              const SizedBox(height: 8),
              Text(
                'Поиск устройств в той же Wi-Fi сети...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _peers.isEmpty
                    ? const Center(child: Text('Пока никого не найдено'))
                    : ListView.builder(
                        itemCount: _peers.length,
                        itemBuilder: (context, index) {
                          final peer = _peers[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.smartphone),
                              title: Text(peer.name),
                              subtitle: Text(peer.ip),
                              onTap: () => _openChatWith(peer),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
