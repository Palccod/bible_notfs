import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static Future<void> requestPermission() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  static Future<void> scheduleNotifications({
    required Map<String, dynamic> verse,
    required TimeOfDay startTime,
    required int intervalHours,
  }) async {
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
      startTime.hour,
      startTime.minute,
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
        interval: Duration(hours: intervalHours),
        timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
        repeats: true,
      ),
    );
  }
}