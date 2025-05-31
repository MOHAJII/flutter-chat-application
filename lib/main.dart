import 'package:exam_mobile/pages/chatbot.page.dart';
import 'package:exam_mobile/pages/login.page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:exam_mobile/blocs/chat/chat_bloc.dart';
import 'package:exam_mobile/pages/model_selection.page.dart';

import 'events/chat/chat_event.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");
    runApp(const MyApp());
  } catch (e) {
    print('Error loading environment variables: $e');
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatBloc()..add(InitializeChatEvent()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        routes: {
          '/': (context) => const ChatBotPage(),
          '/models': (context) => ModelSelectionPage(),
          '/bot': (context) => const ChatBotPage(),
        },
        theme: ThemeData(
          primaryColor: Colors.redAccent,
          useMaterial3: true,
        ),
      ),
    );
  }
}
