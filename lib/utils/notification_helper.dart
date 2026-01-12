import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationHelper {
  static Future<void> showWaterLevelAlert({
    required String deviceName,
    required int waterLevel,
    required bool isEmergency,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'alerts',
        title: isEmergency ? '🚨 EMERGENCY: $deviceName' : '⚠️ Water Level Alert',
        body: isEmergency
            ? 'Water level critical at $waterLevel%! Pump stopped.'
            : 'Water level is at $waterLevel%',
        notificationLayout: NotificationLayout.BigText,
        category: NotificationCategory.Alarm,
        wakeUpScreen: true,
        criticalAlert: isEmergency,
      ),
    );
  }

  static Future<void> showDeviceStatusChange({
    required String deviceName,
    required bool isOn,
    String? reason,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'events',
        title: '$deviceName ${isOn ? 'turned ON' : 'turned OFF'}',
        body: reason ?? 'Device status changed',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  static Future<void> showGasAlert({
    required String deviceName,
    required double lpgValue,
    required double coValue,
  }) async {
    if (lpgValue > 50 || coValue > 30) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'alerts',
          title: '🚨 GAS ALERT: $deviceName',
          body: 'LPG: ${lpgValue.toStringAsFixed(1)}ppm, CO: ${coValue.toStringAsFixed(1)}ppm',
          notificationLayout: NotificationLayout.BigText,
          category: NotificationCategory.Alarm,
          wakeUpScreen: true,
          criticalAlert: true,
        ),
      );
    }
  }

  static Future<void> showLowBatteryAlert({
    required String deviceName,
    required int batteryLevel,
  }) async {
    if (batteryLevel <= 20) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'alerts',
          title: '🔋 Low Battery: $deviceName',
          body: 'Battery at $batteryLevel%',
          notificationLayout: NotificationLayout.Default,
        ),
      );
    }
  }
}
