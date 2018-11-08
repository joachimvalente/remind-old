// See https://flutterbyexample.com/set-up-inherited-widget-app-state

import 'package:flutter/material.dart';

class RemindThemeData {
  /// Color of links for web and email intents.
  final Color linkColor;

  /// Color of main text for done items.
  final Color doneTextColor;

  /// Color of alert captions.
  final Color alertCaptionColor;

  /// Color of the trash icon on dismiss.
  final Color deleteIconColor;

  RemindThemeData({
    @required this.linkColor,
    @required this.doneTextColor,
    @required this.alertCaptionColor,
    @required this.deleteIconColor,
  });
}

class RemindTheme extends StatefulWidget {
  final Widget child;
  final RemindThemeData remindThemeData;

  RemindTheme({
    @required this.child,
    this.remindThemeData,
  });

  static _RemindThemeState of(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(_InheritedStateContainer)
            as _InheritedStateContainer)
        .data;
  }

  @override
  _RemindThemeState createState() => new _RemindThemeState();
}

class _RemindThemeState extends State<RemindTheme> {
  RemindThemeData get themeData => widget.remindThemeData;

  @override
  Widget build(BuildContext context) {
    return new _InheritedStateContainer(
      data: this,
      child: widget.child,
    );
  }
}

class _InheritedStateContainer extends InheritedWidget {
  final _RemindThemeState data;

  _InheritedStateContainer({
    Key key,
    @required this.data,
    @required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(_InheritedStateContainer old) => old.data != data;
}
