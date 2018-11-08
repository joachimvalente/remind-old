import 'package:cloud_firestore/cloud_firestore.dart';

/// Encapsulates reminder attributes.
class Reminder {
  /// The text.
  final String text;

  /// Datastore reference.
  final DocumentReference reference;

  /// Raw data from datastore.
  final dynamic rawData;

  /// Whether it's done.
  final bool done;

  /// Date of creation.
  final DateTime dateCreated;

  /// A preview map.
  ///
  /// For example if the text contains an email address it could be
  /// { 'intent': 'email', 'emailAddress': 'john@doe.com' }.
  final Map<String, dynamic> preview;

  /// When to send a reminder.
  final DateTime alert;

  Reminder(this.text,
      {this.reference,
      this.rawData,
      this.done = false,
      dateCreated,
      this.preview,
      this.alert})
      : dateCreated = dateCreated ?? DateTime.now();

  Reminder.fromSnapshot(DocumentSnapshot snapshot)
      : this(snapshot['text'],
            reference: snapshot.reference,
            rawData: snapshot.data,
            done: snapshot['done'] != null,
            dateCreated: snapshot['dateCreated']?.toDate(),
            preview: snapshot['preview'] != null
                ? Map<String, dynamic>.from(snapshot['preview'])
                : null,
            alert:
                // Don't show alerts set in the past.
                (snapshot['alert']?.toDate()?.isAfter(DateTime.now()) ?? false)
                    ? snapshot['alert'].toDate()
                    : null);
}
