import 'dart:math';
import 'package:canonical_url/canonical_url.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

import 'package:Remind/main.dart';
import 'package:Remind/model/reminder.dart';
import 'package:Remind/themes/themes.dart';
import 'package:Remind/util/regex.dart';
import 'package:Remind/widgets/card_action.dart';

/// A visual card representing a reminder.
class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final TextEditingController _controller;
  final _focusNode = FocusNode();

  static bool showTimesWithTimeago = true;

  ReminderCard(this.reminder)
      : _controller = TextEditingController(text: reminder.text) {
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _updateText();
      }
    });

    _initializeNotification();
  }

  @override
  Widget build(BuildContext context) {
    // Housekeeping.
    Map<String, FieldValue> fieldsToDelete = {};
    if (reminder.rawData['_dummyForAutofocus'] != null) {
      fieldsToDelete['_dummyForAutofocus'] = FieldValue.delete();
    }
    if (reminder.rawData['_dummy'] != null) {
      fieldsToDelete['_dummy'] = FieldValue.delete();
    }
    if (fieldsToDelete.isNotEmpty) {
      reminder.reference.updateData(fieldsToDelete);
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Dismissible(
        key: Key(reminder.reference.documentID),
        direction: DismissDirection.startToEnd,
        // TODO: Remove the padding between foreground and background.
        background: Card(
          color: Theme.of(context).errorColor,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Icon(Icons.delete,
                    color: RemindTheme.of(context).themeData.deleteIconColor),
              ),
            ],
            mainAxisAlignment: MainAxisAlignment.start,
          ),
        ),
        onDismissed: (direction) {
          _delete(context, direction);
        },
        child: Card(
          child: Column(
            children: _buildRows(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRows(BuildContext context) {
    List<Widget> rows = <Widget>[];

    // Build main row.
    rows.add(Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          // "Done" checkbox.
          Checkbox(
            value: reminder.done,
            onChanged: (val) {
              _onChanged(context, val);
            },
          ),

          // Central text field.
          _buildTextField(context),

          // Alert icon.
          IconButton(
            icon: Icon(
              reminder.alert == null ? MdiIcons.bellOutline : MdiIcons.bell,
            ),
            onPressed: () {
              _toggleAlert(context);
            },
          ),
        ],
      ),
    ));

    // Add previews when applicable.
    if (reminder.preview != null) {
      rows.add(Divider(
        height: 0.0,
      ));
      switch (reminder.preview['intent']) {
        case 'website':
          rows.add(cardAction(
            context: context,
            reminderRef: reminder.reference,
            text: 'OPEN LINK',
            action: () {
              _openLink(context, reminder.preview['url']);
            },
            icon: Icon(MdiIcons.linkVariant),
          ));
          break;
        case 'email':
          rows.add(cardAction(
            context: context,
            reminderRef: reminder.reference,
            text: 'SEND EMAIL',
            action: () {
              _sendEmail(context, reminder.preview['emailAddress']);
            },
            icon: Icon(MdiIcons.email),
          ));
          break;
      }
    }

    return rows;
  }

  void _onChanged(BuildContext context, bool value) {
    FocusScope.of(context).requestFocus(FocusNode());
    reminder.reference.updateData({'done': value ? true : FieldValue.delete()});
  }

  void _toggleAlert(BuildContext context) async {
    // TODO: Find a way not to repeat this FocusScope(...) everywhere.
    FocusScope.of(context).requestFocus(FocusNode());

    if (reminder.alert == null) {
      DateTime date = await showDatePicker(
          context: context,
          firstDate: DateTime(2000),
          initialDate: DateTime.now(),
          lastDate: DateTime(3000));
      if (date == null) {
        return;
      }
      TimeOfDay time = await showTimePicker(
          context: context, initialTime: TimeOfDay(hour: 8, minute: 0));
      if (time == null) {
        return;
      }
      final dateTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (dateTime.isBefore(DateTime.now())) {
        Fluttertoast.showToast(msg: 'Cannot add an alert in the past');
        return;
      }
      reminder.reference.updateData({'alert': Timestamp.fromDate(dateTime)});
    } else {
      // reminder.alert != null
      reminder.reference.updateData({'alert': FieldValue.delete()});

      // Keeping this code for reference. For now let's not ask confirmation.
//      showDialog(
//        context: context,
//        builder: (context) => AlertDialog(
//              title: Text('Remove alert?'),
//              actions: <Widget>[
//                FlatButton(
//                  child: Text('NO'),
//                  onPressed: () {
//                    Navigator.of(context).pop();
//                  },
//                ),
//                RaisedButton(
//                  child: Text('YES'),
//                  onPressed: () {
//                    reminder.reference
//                        .updateData({'alert': FieldValue.delete()});
//                    Navigator.of(context).pop();
//                  },
//                )
//              ],
//            ),
//      );
    }
  }

  void _openLink(BuildContext context, url) async {
    FocusScope.of(context).requestFocus(FocusNode());
    if (await canLaunch(url)) {
      try {
        await launch(url);
      } on PlatformException catch (e) {
        // Fails when website is reachable.
        Fluttertoast.showToast(msg: e.message);
      }
    } else {
      Fluttertoast.showToast(msg: 'Cannot open URL $url');
    }
  }

  void _sendEmail(BuildContext context, emailAddress) async {
    final url = 'mailto:$emailAddress';
    FocusScope.of(context).requestFocus(FocusNode());
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Fluttertoast.showToast(msg: 'Cannot send email to $emailAddress');
    }
  }

  void _delete(BuildContext context, DismissDirection direction) async {
    Scaffold.of(context).removeCurrentSnackBar();
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text(_controller.text.isEmpty
          ? 'Deleted empty reminder'
          : 'Deleted "${_controller.text}"'),
      action: SnackBarAction(label: 'UNDO', onPressed: _undoDelete),
    ));

    await RemindApp.notifications.cancel(reminder.reference.hashCode);
    reminder.reference.delete();
  }

  void _undoDelete() {
    // If we edited the field just before deletion, rawData is out-of-date.
    reminder.rawData['text'] = _controller.text;
    reminder.reference.setData(reminder.rawData);
  }

  Widget _buildTextField(BuildContext context) {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            maxLines: null,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration.collapsed(
              hintText: 'Remind me to...',
              hintStyle: TextStyle(fontSize: 12.0),
            ),
            style: Theme.of(context).textTheme.subhead.copyWith(
                  color: reminder.done
                      ? RemindTheme.of(context).themeData.doneTextColor
                      : null,
                ),
            enabled: !reminder.done,
            onSubmitted: _updateText,
            focusNode: _focusNode,
            textCapitalization: TextCapitalization.sentences,
          ),
          reminder.alert != null
              ? InkWell(
                  onTap: () async {
                    showTimesWithTimeago = !showTimesWithTimeago;
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    prefs.setBool('showTimesWithTimeago', showTimesWithTimeago);
                    _forceRedraw();
                  },
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Icon(
                          MdiIcons.bell,
                          size: 12.0,
                          color: RemindTheme.of(context)
                              .themeData
                              .alertCaptionColor,
                        ),
                      ),
                      Text(
                          (showTimesWithTimeago
                              ? timeago.format(reminder.alert,
                                  allowFromNow: true)
                              : MaterialLocalizations.of(context)
                                      .formatFullDate(reminder.alert) +
                                  ' ' +
                                  MaterialLocalizations.of(context)
                                      .formatTimeOfDay(TimeOfDay.fromDateTime(
                                          reminder.alert))),
                          style: Theme.of(context).textTheme.caption.copyWith(
                                color: RemindTheme.of(context)
                                    .themeData
                                    .alertCaptionColor,
                              )),
                    ],
                  ),
                )
              : Container(),
        ],
      ),
    );
  }

  void _updateText([String value]) {
    Map<String, dynamic> data = {
      'text': _controller.text,
    };

    data['preview'] = _parsePreview(_controller.text);

    try {
      reminder.reference.updateData(data);
    } on PlatformException {
      // Sometimes fails, for example if another client deleted the reminder in
      // the meantime.
    }
  }

  dynamic _parsePreview(String text) {
    // Parse email addresses.
    final emailMatch = emailRegex.stringMatch(_controller.text);
    if (emailMatch != null) {
      return <String, dynamic>{
        'intent': 'email',
        'emailAddress': emailMatch,
      };
    }

    // Parse URLs.
    final urlMatch = urlRegex.stringMatch(_controller.text);
    if (urlMatch != null) {
      String url = UrlCanonicalizer().canonicalize(urlMatch);
      if (!url.startsWith('http')) {
        // Not the most robust, but does the job.
        url = 'http://$url';
      }

      return <String, dynamic>{
        'intent': 'website',
        'url': url,
      };
    }

    // Fallback to no preview.
    return FieldValue.delete();
  }

  void _forceRedraw() {
    // Make a dummy edit to force redraw.
    reminder.reference.updateData({'_dummy': Random().nextDouble()});
  }

  // TODO: Use FCM instead. If a reminder is added or deleted from another
  // device, this will get out of sync.
  void _initializeNotification() async {
    // Cancel previous notification.
    await RemindApp.notifications.cancel(reminder.reference.hashCode);
    if (reminder.alert != null) {
      var androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'remind_app_channel_id', 'Remind App', 'Remind App');
      var iOSPlatformChannelSpecifics = IOSNotificationDetails();
      NotificationDetails platformChannelSpecifics = NotificationDetails(
          androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
      await RemindApp.notifications.schedule(
          reminder.reference.hashCode,
          'Reminder alert',
          reminder.text,
          reminder.alert,
          platformChannelSpecifics);
    }
  }
}
