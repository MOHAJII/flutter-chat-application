import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  List<Map<String, String>> messages = [];

  final TextEditingController _userController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isDisposed = false;

  // Get API key from environment variables
  String get _apiKey => dotenv.env['HUGGING_FACE_API_KEY'] ?? '';

  @override
  void initState() {
    super.initState();
    _checkApiKey();
    // Add welcome message
    messages.add({
      "type": "bot",
      "content": "Hello! I'm your AI assistant. How can I help you today?"
    });
  }

  void _checkApiKey() {
    if (_apiKey.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorDialog(
          'API Key Missing',
          'Hugging Face API key not found in environment variables. Please add HUGGING_FACE_API_KEY to your .env file.',
        );
      });
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _userController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final String question = _userController.text.trim();
    if (question.isEmpty || _isLoading) return;

    // Check if API key is available
    if (_apiKey.isEmpty) {
      _showErrorDialog(
        'Configuration Error',
        'API key is not configured. Please check your .env file.',
      );
      return;
    }

    _userController.clear();

    setState(() {
      messages.add({"type": "user", "content": question});
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      // Add loading message
      setState(() {
        messages.add({"type": "bot", "content": "Thinking..."});
      });
      _scrollToBottom();

      const String apiUrl = "https://router.huggingface.co/novita/v3/openai/chat/completions";

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "messages": [
            {"role": "user", "content": question},
          ],
          "model": "meta-llama/llama-3.3-70b-instruct",
          "stream": false
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (!_isDisposed) {
        setState(() {
          messages.removeLast(); // Remove loading message
        });

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final String answer = data['choices'][0]['message']['content'] ?? 'No response received';

          setState(() {
            messages.add({"type": "bot", "content": answer});
          });
        } else if (response.statusCode == 401) {
          setState(() {
            messages.add({
              "type": "bot",
              "content": "Authentication failed. Please check your API key configuration."
            });
          });
          debugPrint("API Authentication Error: Invalid API key");
        } else if (response.statusCode == 429) {
          setState(() {
            messages.add({
              "type": "bot",
              "content": "Rate limit exceeded. Please wait a moment before trying again."
            });
          });
          debugPrint("API Rate Limit Error: ${response.statusCode}");
        } else {
          setState(() {
            messages.add({
              "type": "bot",
              "content": "Sorry, I encountered an error. Please try again later. (Error: ${response.statusCode})"
            });
          });
          debugPrint("API Error ${response.statusCode}: ${response.body}");
        }
      }
    } catch (e) {
      if (!_isDisposed) {
        setState(() {
          if (messages.isNotEmpty && messages.last["content"] == "Thinking...") {
            messages.removeLast();
          }
          messages.add({
            "type": "bot",
            "content": "Sorry, I couldn't process your request. Please check your internet connection and try again."
          });
        });
        debugPrint("Request failed: $e");
      }
    } finally {
      if (!_isDisposed) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  Widget _buildMessageBubble(Map<String, String> message, int index) {
    final bool isUser = message['type'] == 'user';
    final String content = message['content'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.smart_toy,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                  bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                content,
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(
                Icons.person,
                size: 20,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Chat Assistant',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Chat'),
                  content: const Text('Are you sure you want to clear all messages?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          messages.clear();
                          messages.add({
                            "type": "bot",
                            "content": "Hello! I'm your AI assistant. How can I help you today?"
                          });
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear chat',
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            tooltip: 'Close chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // API Key Status Indicator (only shown if key is missing)
          if (_apiKey.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'API key not configured. Check your .env file.',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: messages.isEmpty
                ? const Center(
              child: Text(
                'Start a conversation!',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(messages[index], index),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: TextField(
                        controller: _userController,
                        enabled: !_isLoading && _apiKey.isNotEmpty,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: _isLoading
                              ? "Please wait..."
                              : _apiKey.isEmpty
                              ? "API key required..."
                              : "Type your message...",
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: (_isLoading || _apiKey.isEmpty)
                          ? Colors.grey.shade300
                          : Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: (_isLoading || _apiKey.isEmpty) ? null : _sendMessage,
                      icon: _isLoading
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.grey.shade600,
                          ),
                        ),
                      )
                          : const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                      tooltip: 'Send message',
                    ),
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