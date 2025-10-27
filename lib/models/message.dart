class Message {
  final int? id;
  final int senderId;
  final int receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  Message({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id:
        json['id'] is int
            ? json['id']
            : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
    senderId:
        json['senderId'] is int
            ? json['senderId']
            : int.parse(json['senderId'].toString()),
    receiverId:
        json['receiverId'] is int
            ? json['receiverId']
            : int.parse(json['receiverId'].toString()),
    content: json['content'] as String? ?? '',
    timestamp: DateTime.parse(json['timestamp'] as String),
    isRead: json['isRead'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'senderId': senderId,
    'receiverId': receiverId,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
  };

  @override
  String toString() =>
      'Message(id: $id, senderId: $senderId, receiverId: $receiverId, content: ${content.length} chars, timestamp: $timestamp, isRead: $isRead)';
}
