import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static Future<void> requestPermission() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  static Future<void> scheduleMultipleNotifications({
    required List<Map<String, dynamic>> verses,
    required TimeOfDay startTime,
    required int intervalMinutes,
    int count = 7,
  }) async {
    // Cancel all previous notifications
    await AwesomeNotifications().cancelAll();

    final now = DateTime.now();
    DateTime nextNotification = DateTime(
      now.year,
      now.month,
      now.day,
      startTime.hour,
      startTime.minute,
    );
    if (nextNotification.isBefore(now)) {
      nextNotification = nextNotification.add(const Duration(days: 1));
    }

    for (int i = 0; i < count && i < verses.length; i++) {
      final verse = verses[i];
      final verseText =
          '${verse['book']} ${verse['chapter']}:${verse['verse']} - ${verse['text']}';

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 100 + i, // unique id for each notification
          channelKey: 'bible_channel',
          title: 'Bible Verse',
          body: verseText,
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar(
          year: nextNotification.year,
          month: nextNotification.month,
          day: nextNotification.day,
          hour: nextNotification.hour,
          minute: nextNotification.minute,
          second: 0,
          millisecond: 0,
          repeats: false,
          timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
        ),
      );
      nextNotification =
          nextNotification.add(Duration(minutes: intervalMinutes));
    }
  }
}
