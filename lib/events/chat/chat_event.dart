import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class SendMessageEvent extends ChatEvent {
  final String message;

  const SendMessageEvent(this.message);

  @override
  List<Object?> get props => [message];
}

class ClearChatEvent extends ChatEvent {}

class InitializeChatEvent extends ChatEvent {}

class ModelSelectedEvent extends ChatEvent {
  final String modelId;
  const ModelSelectedEvent(this.modelId);

  @override
  List<Object?> get props => [modelId];
}

