import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:Remind/pages/home_page.dart';
import 'package:Remind/pages/login_page.dart';
import 'package:Remind/pages/splash_screen.dart';
import 'package:Remind/themes/remind_theme_data.dart';
import 'package:Remind/themes/themes.dart';
import 'package:Remind/widgets/reminder_card.dart';

void main() async {
  Firestore.instance.settings(timestampsInSnapshotsEnabled: true);

  // TODO: Move this *after* showing SplashScreen.
  SharedPreferences prefs = await SharedPreferences.getInstance();
  ReminderCard.showTimesWithTimeago =
      prefs.getBool('showTimesWithTimeago') ?? true;
  RemindApp.useDarkTheme = prefs.getBool('useDarkTheme') ?? true;

  runApp(RemindApp());
}

class RemindApp extends StatelessWidget {
  static bool useDarkTheme;
  static FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  @override
  Widget build(BuildContext context) {
    _initializeLocalNotificationsPlugin(context);

    return StreamBuilder<FirebaseUser>(
      stream: FirebaseAuth.instance.onAuthStateChanged,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        }
        if (!snapshot.hasData) {
          return RemindTheme(
            child: MaterialApp(
              home: LoginPage(),
              theme: darkTheme(),
            )
          );
        }
        return _buildHomePage(snapshot.data);
      },
    );
  }

  Widget _buildHomePage(FirebaseUser user) {
    return DynamicTheme(
      defaultBrightness: useDarkTheme ? Brightness.dark : Brightness.light,
      data: (brightness) => ThemeData(brightness: brightness),
      themedWidgetBuilder: (context, theme) {
        return RemindTheme(
          child: MaterialApp(
            title: 'Remind',
            home: HomePage(user),
            theme: theme.brightness == Brightness.dark
                ? darkTheme()
                : lightTheme(),
          ),
          remindThemeData: theme.brightness == Brightness.dark
              ? darkRemindTheme()
              : lightRemindTheme(),
        );
      },
    );
  }

  void _initializeLocalNotificationsPlugin(BuildContext context) {
    var settingsAndroid = AndroidInitializationSettings('ic_stat_alarm');
    var settingsIOS = IOSInitializationSettings();
    notifications.initialize(
      InitializationSettings(settingsAndroid, settingsIOS),
      onSelectNotification: (payload) {
        _onSelectNotification(context, payload);
      },
    );
  }

  Future _onSelectNotification(BuildContext context, String payload) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RemindApp()),
    );
  }
}
