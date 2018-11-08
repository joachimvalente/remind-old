import 'package:flutter/material.dart';

/// A header looking like -------------- Title ---------------
class SectionHeader extends StatelessWidget {
  final String title;

  SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            color: Colors.grey,
            height: 1.0,
            margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          ),
        ),
        Text(title, style: Theme.of(context).textTheme.caption),
        Expanded(
          child: Container(
            color: Colors.grey,
            height: 1.0,
            margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          ),
        ),
      ],
    );
  }
}
