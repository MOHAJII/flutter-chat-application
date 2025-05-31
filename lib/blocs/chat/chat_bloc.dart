import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../events/chat/chat_event.dart';
import '../../states/chat/chat_state.dart';
import '../../models/chat_message.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  String _selectedModel = 'meta-llama/llama-3.3-70b-instruct'; // Default model

  ChatBloc() : super(ChatInitial()) {
    on<InitializeChatEvent>(_onInitialize);
    on<SendMessageEvent>(_onSendMessage);
    on<ClearChatEvent>(_onClearChat);
    on<ModelSelectedEvent>(_onModelSelected);
  }

  String get _apiKey => dotenv
