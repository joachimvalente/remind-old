import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Center(
        child: Text(
          'Remind.',
          style: Theme.of(context).accentTextTheme.display3.copyWith(
                color: Colors.white,
              ),
        ),
      ),
    );
  }
}
