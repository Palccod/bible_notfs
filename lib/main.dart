import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'bible_channel',
        channelName: 'Bible Verses',
        channelDescription: 'Bible verse notifications',
        defaultColor: Colors.blue,
        importance: NotificationImportance.High,
        channelShowBadge: true,
      ),
    ],
    debug: true,
  );

  runApp(const BibleNotfsApp());
}

class BibleNotfsApp extends StatelessWidget {
  const BibleNotfsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Way Up',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}
