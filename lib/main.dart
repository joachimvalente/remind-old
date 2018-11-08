import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:remind/pages/home_page.dart';
import 'package:remind/pages/login_page.dart';
import 'package:remind/pages/splash_screen.dart';
import 'package:remind/themes/remind_theme_data.dart';
import 'package:remind/themes/themes.dart';
import 'package:remind/widgets/reminder_card.dart';

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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FirebaseUser>(
      stream: FirebaseAuth.instance.onAuthStateChanged,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        }
        if (!snapshot.hasData) {
          return MaterialApp(
            home: LoginPage(),
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
}
