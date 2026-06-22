class Peer {
  final String id;
  final String name;
  final String ip;
  final int port;
  final DateTime lastSeen;

  Peer({
    required this.id,
    required this.name,
    required this.ip,
    required this.port,
    required this.lastSeen,
  });
}
