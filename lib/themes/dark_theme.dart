import 'package:flutter/material.dart';

import 'package:Remind/themes/remind_theme_data.dart';

ThemeData darkTheme() {
  return ThemeData.dark().copyWith(
    accentColor: Colors.orange[300],
    toggleableActiveColor: Colors.green,
    iconTheme: IconThemeData(color: Colors.grey),
    buttonColor: Colors.grey[800],
    dialogBackgroundColor: Colors.grey[700],
  );
}

RemindThemeData darkRemindTheme() {
  return RemindThemeData(
    linkColor: Colors.orange[200],
    doneTextColor: Colors.grey[400],
    alertCaptionColor: Colors.grey,
    deleteIconColor: Colors.white,
  );
}
