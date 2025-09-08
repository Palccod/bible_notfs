import 'package:flutter/material.dart';
import '../services/bible_service.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _intervalHours = 24;
  final List<int> _intervalOptions = [1, 2, 4, 6, 8, 12, 24];
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);

  bool _loading = true;
  late BibleService _bibleService;

  @override
  void initState() {
    super.initState();
    _bibleService = BibleService();
    _bibleService.loadBibleVerses().then((_) {
      setState(() {
        _loading = false;
      });
    });
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

  Future<void> _scheduleNotifications() async {
    final verse = await _bibleService.getNextVerse();
    await NotificationService.scheduleNotifications(
      verse: verse,
      startTime: _startTime,
      intervalHours: _intervalHours,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                const Spacer(),
                const Text(
                  'Way Up',
                  style: TextStyle(),
                ),
                const Spacer(),
              ],
            ),
            SizedBox(height: 50),
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
                await NotificationService.requestPermission();
                await _scheduleNotifications();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Notification scheduled from ${_startTime.format(context)} every $_intervalHours hour(s)!')),
                );
              },
              child: const Text('Enable Bible Verse Notification'),
            ),
          ],
        ),
      ),
    );
  }
}
