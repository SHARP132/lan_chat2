import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Одно TCP-соединение между двумя устройствами для обмена сообщениями.
class ChatConnection {
  final Socket socket;
  final String remoteName;
  final _messagesController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messagesController.stream;

  ChatConnection(this.socket, {required this.remoteName}) {
    socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      (line) {
        try {
          final data = jsonDecode(line) as Map<String, dynamic>;
          _messagesController.add(data);
        } catch (_) {
          // повреждённая строка — пропускаем
        }
      },
      onDone: () => _messagesController.close(),
      onError: (_) => _messagesController.close(),
    );
  }

  void send(String text, String fromName) {
    final payload = jsonEncode({'text': text, 'name': fromName});
    socket.write('$payload\n');
  }

  void close() => socket.close();
}

/// Слушает входящие подключения от других устройств в сети.
class ChatServer {
  final int port;
  ServerSocket? _server;
  final _incomingController = StreamController<ChatConnection>.broadcast();

  Stream<ChatConnection> get incomingConnections => _incomingController.stream;

  ChatServer({required this.port});

  Future<void> start() async {
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, port, shared: true);
    _server!.listen((socket) {
      final conn = ChatConnection(socket, remoteName: socket.remoteAddress.address);
      _incomingController.add(conn);
    });
  }

  static Future<ChatConnection> connectTo(
    String ip,
    int port, {
    required String remoteName,
  }) async {
    final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));
    return ChatConnection(socket, remoteName: remoteName);
  }

  void stop() {
    _server?.close();
    _incomingController.close();
  }
}
