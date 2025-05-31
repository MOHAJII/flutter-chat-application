import 'package:exam_mobile/pages/chatbot.page.dart';
import 'package:exam_mobile/pages/login.page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");
    runApp(const MyApp());
  } catch (e) {
    print('Error loading environment variables: $e');
    // Run the app anyway, but you might want to show an error screen
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => const LoginPage(),
        '/bot': (context) => const ChatBotPage(),
      },
      theme: ThemeData(
        primaryColor: Colors.blueAccent,
        useMaterial3: true, // Enable Material 3
      ),
    );
  }
}
