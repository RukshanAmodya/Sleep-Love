import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  static Future<void> showProgress(int progress, int total) async {
    final androidDetail = AndroidNotificationDetails(
      'setup_channel', 
      'App Setup',
      channelDescription: 'Showing setup progress',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: total,
      progress: progress,
      ongoing: true,
      onlyAlertOnce: true,
    );
    
    await _plugin.show(
      100, 
      'Setting up Sleep Love', 
      'Preparing your experience... $progress/$total', 
      NotificationDetails(android: androidDetail),
    );
  }

  static Future<void> showComplete() async {
    const androidDetail = AndroidNotificationDetails(
      'setup_channel', 
      'App Setup',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _plugin.cancel(100);
    await _plugin.show(
      101, 
      'Setup Complete!', 
      'Your premium sounds are ready to play.', 
      const NotificationDetails(android: androidDetail),
    );
  }
}
