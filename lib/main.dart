import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'providers/app_provider.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize AwesomeNotifications
  await AwesomeNotifications().initialize(
    null, // Default app icon
    [
      NotificationChannel(
        channelKey: 'alerts',
        channelName: 'Alerts',
        channelDescription: 'Important alerts and warnings',
        defaultColor: Colors.red,
        ledColor: Colors.red,
        importance: NotificationImportance.High,
        playSound: true,
        enableVibration: true,
      ),
      NotificationChannel(
        channelKey: 'events',
        channelName: 'Device Events',
        channelDescription: 'Device status changes',
        defaultColor: Colors.blue,
        ledColor: Colors.blue,
        importance: NotificationImportance.Default,
        playSound: true,
      ),
    ],
  );
  
  // Request notification permissions
  await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const HomeCircuitApp());
}

class HomeCircuitApp extends StatelessWidget {
  const HomeCircuitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..initialize(),
      child: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            title: provider.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const MainShell(),
          );
        },
      ),
    );
  }
}
