import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:Remind/model/reminder.dart';
import 'package:Remind/util/datetime.dart';
import 'package:Remind/widgets/reminder_card.dart';
import 'package:Remind/widgets/section_header.dart';

class HomePage extends StatelessWidget {
  final FirebaseUser firebaseUser;
  final String _collection;

  HomePage(this.firebaseUser)
      : _collection = 'users/${firebaseUser.uid}/reminders';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Remind'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: () async {
              final useDarkTheme =
                  DynamicTheme.of(context).brightness == Brightness.light;
              DynamicTheme.of(context).setBrightness(
                  useDarkTheme ? Brightness.dark : Brightness.light);
              (await SharedPreferences.getInstance())
                  .setBool('useDarkTheme', useDarkTheme);
            },
          ),
          IconButton(
            icon: Icon(MdiIcons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await GoogleSignIn().signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance.collection(_collection).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return _buildProgressBar();
          }
          return _buildBody(context, snapshot.data);
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          _addReminder(context);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, QuerySnapshot snapshot) {
    List<Reminder> reminders =
        snapshot.documents.map((doc) => Reminder.fromSnapshot(doc)).toList();
    reminders.sort((a, b) => -a.dateCreated.compareTo(b.dateCreated));

    // Placeholder screen for zero reminders.
    if (reminders.isEmpty) {
      return Container(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(MdiIcons.emoticonHappy, size: 72.0),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('All done',
                    style: Theme.of(context).textTheme.headline),
              ),
            ],
          ),
        ),
      );
    }

    final dateTimeUtil = DateTimeUtil(context);
    List<Widget> sections = <Widget>[];

    void addSection(String header, DateTimePredicate predicate) {
      final sectionReminders =
          reminders.where((r) => predicate(r.dateCreated)).toList();
      if (sectionReminders.length > 0) {
        // Header.
        sections.add(SectionHeader(header));

        // Content.
        sections.add(Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: sectionReminders
                .map((reminder) => ReminderCard(reminder))
                .toList(),
          ),
        ));
      }
    }

    // Add spacer at the beginning.
    sections.add(Container(
      height: 16.0,
    ));

    // Build each section.
    addSection('Today', dateTimeUtil.isToday);
    addSection('Yesterday', dateTimeUtil.isYesterday);
    addSection('This week', dateTimeUtil.isEarlierThisWeek);
    addSection('Last week', dateTimeUtil.isLastWeek);
    addSection('Earlier this month', dateTimeUtil.isEarlierThisMonth);
    addSection('Last month', dateTimeUtil.isLastMonth);
    addSection('Older', dateTimeUtil.isBeforeLastMonth);

    // Add spacer at the end (to make sure the FAB doesn't occlude the last
    // reminder).
    sections.add(Container(
      height: 64.0,
    ));

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: ListView(
        children: sections,
      ),
    );
  }

  Widget _buildProgressBar() {
    return LinearProgressIndicator();
  }

  void _addReminder(BuildContext context) async {
    // TODO: Autofocus.
    FocusScope.of(context).requestFocus(FocusNode());
    Firestore.instance.collection(_collection).add({
      'text': '',
      'dateCreated': Timestamp.fromDate(DateTime.now()),
    });
  }
}
