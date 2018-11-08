import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:Remind/themes/themes.dart';

typedef CardActionCallback = void Function();

Widget cardAction(
    {@required BuildContext context,
    @required DocumentReference reminderRef,
    @required String text,
    @required CardActionCallback action,
    @required Icon icon}) {
  return Row(
    children: <Widget>[
      FlatButton(
        textColor: RemindTheme.of(context).themeData.linkColor,
        child: Row(
          children: <Widget>[
            icon,
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Row(
                children: <Widget>[
                  Text(text),
                ],
              ),
            ),
          ],
        ),
        onPressed: action,
      ),
      Expanded(child: Container()),
      Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: IconButton(
          icon: Icon(MdiIcons.close, size: 16.0),
          onPressed: () {
            reminderRef.updateData({'preview': FieldValue.delete()});
          },
        ),
      )
    ],
  );
}
