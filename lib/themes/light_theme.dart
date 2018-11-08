import 'package:flutter/material.dart';

import 'package:Remind/themes/remind_theme_data.dart';

ThemeData lightTheme() {
  return ThemeData.light().copyWith(
    primaryColor: ThemeData.dark().primaryColor,
    scaffoldBackgroundColor: Colors.grey[200],
    accentColor: Colors.orange[700],
    toggleableActiveColor: Colors.green,
    iconTheme: IconThemeData(color: Colors.grey),
    buttonColor: Colors.grey[100],
  );
}

RemindThemeData lightRemindTheme() {
  return RemindThemeData(
    linkColor: Colors.orange[800],
    doneTextColor: Colors.grey[600],
    alertCaptionColor: Colors.grey,
    deleteIconColor: Colors.white,
  );
}
