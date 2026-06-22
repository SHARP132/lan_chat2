import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../services/chat_network.dart';

class ChatScreen extends StatefulWidget {
  final ChatConnection connection;
  final String myName;
  final String peerLabel;

  const ChatScreen({
    super.key,
    required this.connection,
    required this.myName,
    required this.peerLabel,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _messages = <ChatMessage>[];

  @override
  void initState() {
    super.initState();
    widget.connection.messages.listen((data) {
      setState(() {
        _messages.add(ChatMessage(
          text: data['text'] as String,
          fromMe: false,
          time: DateTime.now(),
        ));
      });
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.connection.send(text, widget.myName);
    setState(() {
      _messages.add(ChatMessage(text: text, fromMe: true, time: DateTime.now()));
    });
    _controller.clear();
  }

  @override
  void dispose() {
    widget.connection.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.peerLabel)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.fromMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: msg.fromMe ? Colors.blue.shade400 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(color: msg.fromMe ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Сообщение...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
