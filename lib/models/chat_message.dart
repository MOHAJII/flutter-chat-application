import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String content;
  final String type;
  final DateTime timestamp;
  final String status; // 'sent', 'delivered', 'read'

  ChatMessage({
    required this.content,
    required this.type,
    this.status = 'sent',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object> get props => [content, type, timestamp, status];

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      content: map['content'] as String,
      type: map['type'] as String,
      status: map['status'] as String? ?? 'sent',
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
