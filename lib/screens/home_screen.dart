import 'package:flutter/material.dart';
import '../services/bible_service.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _intervalMinutes = 60 * 24; // Default: 24 hours in minutes
  final List<Map<String, dynamic>> _intervalOptions = [
    {'label': '2 minutes', 'value': 2},
    {'label': '1 hour', 'value': 60},
    {'label': '2 hours', 'value': 120},
    {'label': '4 hours', 'value': 240},
    {'label': '6 hours', 'value': 360},
    {'label': '8 hours', 'value': 480},
    {'label': '12 hours', 'value': 720},
    {'label': '24 hours', 'value': 1440},
  ];
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);

  bool _loading = true;
  late BibleService _bibleService;

  @override
  void initState() {
    super.initState();
    _bibleService = BibleService();
    _loadSettings().then((_) {
      _bibleService.loadBibleVerses().then((_) {
        setState(() {
          _loading = false;
        });
      });
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('start_hour') ?? 8;
    final minute = prefs.getInt('start_minute') ?? 0;
    final interval = prefs.getInt('interval_minutes') ?? 1440;
    setState(() {
      _startTime = TimeOfDay(hour: hour, minute: minute);
      _intervalMinutes = interval;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('start_hour', _startTime.hour);
    await prefs.setInt('start_minute', _startTime.minute);
    await prefs.setInt('interval_minutes', _intervalMinutes);
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
      await _saveSettings();
    }
  }

  String _intervalLabel() {
    if (_intervalMinutes < 60) {
      return 'Every $_intervalMinutes minute(s)';
    } else {
      return 'Every ${_intervalMinutes ~/ 60} hour(s)';
    }
  }

  Future<void> _scheduleNotifications() async {
    final verses = <Map<String, dynamic>>[];
    for (int i = 0; i < 7; i++) {
      verses.add(await _bibleService.getNextVerse());
    }
    await NotificationService.scheduleMultipleNotifications(
      verses: verses,
      startTime: _startTime,
      intervalMinutes: _intervalMinutes,
      count: 7,
    );
    await _saveSettings();
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
        body: Container(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {},
                  ),
                  const Text(
                    'Way Up!',
                    style: TextStyle(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 50),
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
                _intervalLabel(),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              DropdownButton<int>(
                value: _intervalMinutes,
                items: _intervalOptions
                    .map((opt) => DropdownMenuItem(
                          value: opt['value'] as int,
                          child: Text('Every ${opt['label']}'),
                        ))
                    .toList(),
                onChanged: (value) async {
                  if (value != null) {
                    setState(() {
                      _intervalMinutes = value;
                    });
                    await _saveSettings();
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
                            'Notification scheduled from ${_startTime.format(context)} ${_intervalLabel()}!')),
                  );
                },
                child: const Text('Enable Bible Verse Notification'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
