import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _intervalHours = 24;
  final List<int> _intervalOptions = [1, 2, 4, 6, 8, 12, 24];
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);

  List<Map<String, dynamic>> _allVerses = [];
  List<int> _shuffledIndices = [];
  int _currentIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBibleVerses();
  }

  Future<void> _loadBibleVerses() async {
    final String jsonString =
        await rootBundle.loadString('assets/bible_verses.json');
    final Map<String, dynamic> data = json.decode(jsonString);
    final List<Map<String, dynamic>> verses = [];

    for (var book in data['books']) {
      for (var chapter in book['chapters']) {
        for (var verse in chapter['verses']) {
          verses.add({
            'book': book['name'],
            'chapter': chapter['chapter'],
            'verse': verse['verse'],
            'text': verse['text'],
          });
        }
      }
    }

    _allVerses = verses;
    await _loadShuffleState();
    setState(() {
      _loading = false;
    });
  }

  Future<void> _loadShuffleState() async {
    final prefs = await SharedPreferences.getInstance();
    final indicesString = prefs.getString('shuffled_indices');
    final currentIndex = prefs.getInt('current_index') ?? 0;

    if (indicesString != null) {
      _shuffledIndices = List<int>.from(json.decode(indicesString));
      _currentIndex = currentIndex;
      // If the verse count changed (e.g. app update), reshuffle
      if (_shuffledIndices.length != _allVerses.length) {
        _reshuffle();
      }
    } else {
      _reshuffle();
    }
  }

  Future<void> _saveShuffleState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shuffled_indices', json.encode(_shuffledIndices));
    await prefs.setInt('current_index', _currentIndex);
  }

  void _reshuffle() {
    _shuffledIndices = List.generate(_allVerses.length, (i) => i);
    _shuffledIndices.shuffle(Random());
    _currentIndex = 0;
    _saveShuffleState();
  }

  Map<String, dynamic> _getNextVerse() {
    if (_shuffledIndices.isEmpty) _reshuffle();
    if (_currentIndex >= _shuffledIndices.length) {
      _reshuffle();
    }
    final verse = _allVerses[_shuffledIndices[_currentIndex]];
    _currentIndex++;
    _saveShuffleState();
    return verse;
  }

  Future<void> _pickStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> scheduleIntervalNotification() async {
    if (_allVerses.isEmpty) return;

    final verse = _getNextVerse();
    final verseText =
        '${verse['book']} ${verse['chapter']}:${verse['verse']} - ${verse['text']}';

    // Cancel previous notifications with the same id
    await AwesomeNotifications().cancel(1);

    // Calculate the first notification time
    final now = DateTime.now();
    DateTime firstNotification = DateTime(
      now.year,
      now.month,
      now.day,
      _startTime.hour,
      _startTime.minute,
    );
    if (firstNotification.isBefore(now)) {
      firstNotification = firstNotification.add(const Duration(days: 1));
    }

    // Schedule the first notification
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'bible_channel',
        title: 'Bible Verse',
        body: verseText,
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        year: firstNotification.year,
        month: firstNotification.month,
        day: firstNotification.day,
        hour: firstNotification.hour,
        minute: firstNotification.minute,
        second: 0,
        millisecond: 0,
        repeats: false,
        timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
      ),
    );

    // Schedule repeating notifications at the interval
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 2,
        channelKey: 'bible_channel',
        title: 'Bible Verse',
        body: verseText,
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationInterval(
        interval: Duration(hours: _intervalHours),
        timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
        repeats: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Way Up'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            // Handle menu action
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Start Time: ${_startTime.format(context)}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _pickStartTime(context),
              child: const Text('Pick Start Time'),
            ),
            const SizedBox(height: 16),
            Text(
              'Interval: Every $_intervalHours hour(s)',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: _intervalHours,
              items: _intervalOptions
                  .map((h) => DropdownMenuItem(
                        value: h,
                        child: Text('Every $h hour(s)'),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _intervalHours = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await AwesomeNotifications()
                    .isNotificationAllowed()
                    .then((isAllowed) async {
                  if (!isAllowed) {
                    await AwesomeNotifications()
                        .requestPermissionToSendNotifications();
                  }
                  await scheduleIntervalNotification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Notification scheduled from ${_startTime.format(context)} every $_intervalHours hour(s)!')),
                  );
                });
              },
              child: const Text('Enable Bible Verse Notification'),
            ),
          ],
        ),
      ),
    );
  }
}
