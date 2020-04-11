import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'jitsi_meeting_listener.dart';

class JitsiMeet {
  static const MethodChannel _channel = const MethodChannel('jitsi_meet');
  static const EventChannel _eventChannel =
      const EventChannel('jitsi_meet_events');

  static List<JitsiMeetingListener> _listeners = <JitsiMeetingListener>[];
  static bool _hasInitialized = false;

  // Alphanumeric, dashes, and underscores only
  static RegExp _allowCharsForRoom = RegExp(
    r"^[a-zA-Z0-9-_]+$",
    caseSensitive: false,
    multiLine: false,
  );

  /// Joins a meeting based on the JitsiMeetingOptions passed in
  static Future<JitsiMeetingResponse> joinMeeting(
      JitsiMeetingOptions options) async {
    assert(options != null, "options are null");
    assert(options.room != null, "room is null");
    assert(options.room.trim().isNotEmpty, "room is empty");
    assert(options.room.trim().length >= 3, "Minimum room length is 3");
    assert(_allowCharsForRoom.hasMatch(options.room),
        "Only alphanumeric, dash, and underscore chars allowed");

    // Validate serverURL is absolute if it is not null or empty
    if (options.serverURL?.isNotEmpty ?? false) {
      assert(Uri.parse(options.serverURL).isAbsolute,
          "URL must be of the format <scheme>://<host>[/path], like https://someHost.com");
    }

    return await _channel
        .invokeMethod<String>('joinMeeting', <String, dynamic>{
          'room': options.room?.trim(),
          'serverURL': options.serverURL?.trim(),
          'subject': options.subject,
          'token': options.token,
          'audioMuted': options.audioMuted,
          'audioOnly': options.audioOnly,
          'videoMuted': options.videoMuted,
          'userDisplayName': options.userDisplayName,
          'userEmail': options.userEmail,
        })
        .then((message) =>
            JitsiMeetingResponse(isSuccess: true, message: message))
        .catchError((error) {
          debugPrint("error: $error, type: ${error.runtimeType}");
          return JitsiMeetingResponse(
              isSuccess: false, message: error.toString(), error: error);
        });
  }

  /// Adds a JitsiMeetingListener that will broadcast conference events
  static addListener(JitsiMeetingListener jitsiMeetingListener) {
    debugPrint('Jitsi Meet - addListener');
    _listeners.add(jitsiMeetingListener);
    if (!_hasInitialized) {
      debugPrint('Jitsi Meet - initializing event channel');
      _eventChannel.receiveBroadcastStream().listen((dynamic event) {
        debugPrint('Jitsi Meet - broadcast event: $event');
        _listeners.forEach((listener) {
          switch (event) {
            case "onConferenceWillJoin":
              if (listener.onConferenceWillJoin != null)
                listener.onConferenceWillJoin();
              break;
            case "onConferenceJoined":
              if (listener.onConferenceJoined != null)
                listener.onConferenceJoined();
              break;
            case "onConferenceTerminated":
              if (listener.onConferenceTerminated != null)
                listener.onConferenceTerminated();
              break;
          }
        });
      }, onError: (dynamic error) {
        debugPrint('Jitsi Meet broadcast error: $error');
        _listeners.forEach((listener) {
          if (listener.onError != null) listener.onError(error);
        });
      });
      _hasInitialized = true;
    }
  }

  /// Removes the JitsiMeetingListener specified
  static removeListener(JitsiMeetingListener jitsiMeetingListener) {
    _listeners.remove(jitsiMeetingListener);
  }

  /// Removes all JitsiMeetingListeners
  static removeAllListeners() {
    _listeners.clear();
  }
}

class JitsiMeetingResponse {
  final bool isSuccess;
  final String message;
  final dynamic error;

  JitsiMeetingResponse({this.isSuccess, this.message, this.error});

  @override
  String toString() {
    return 'JitsiMeetingResponse{isSuccess: $isSuccess, message: $message, error: $error}';
  }
}

class JitsiMeetingOptions {
  String room;
  String serverURL;
  String subject;
  String token;
  bool audioMuted;
  bool audioOnly;
  bool videoMuted;
  String userDisplayName;
  String userEmail;

  @override
  String toString() {
    return 'JitsiMeetingOptions{room: $room, serverURL: $serverURL, subject: $subject, token: $token, audioMuted: $audioMuted, audioOnly: $audioOnly, videoMuted: $videoMuted, userDisplayName: $userDisplayName, userEmail: $userEmail}';
  }

/* Not used yet, needs more research
  Bundle colorScheme;
  Bundle featureFlags;
  String userAvatarURL;
*/

}
