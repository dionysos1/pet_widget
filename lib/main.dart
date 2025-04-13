import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pet_widget/pet_home.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pet_widget/utils.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  initializeApp();

  runApp(const PetApp());
}

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await notificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  await notificationsPlugin
      .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);

  await requestNotificationPermissionAndroid();
  await requestExactAlarmPermission();
}

Future<void> requestNotificationPermissionAndroid() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

class PetApp extends StatelessWidget {
  const PetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent),
        useMaterial3: true,
      ),
      home: const PetHome(),
    );
  }
}
