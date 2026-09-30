import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:maharashtra_tyres/widgets/reminder_notification_popup.dart';

class ReminderNotificationService {
  ReminderNotificationService._();

  static final ReminderNotificationService instance =
      ReminderNotificationService._();

  static const String _enabledKey = 'reminder_notifications_enabled';
  static const String _remindersKey = 'saved_reminders_list';
  static const String _channelId = 'tyre_reminders';
  static const String _channelName = 'Reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final Map<int, Timer> _webTimers = {};

  GlobalKey<NavigatorState>? _navigatorKey;
  String? _initialNotificationPayload;
  bool _initialized = false;

  Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    if (_initialized) return;
    _navigatorKey = navigatorKey;

    try {
      tz_data.initializeTimeZones();
      try {
        final localTimezone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
      } catch (error) {
        debugPrint('Could not read the device timezone: $error');
      }

      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_stat_reminder'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        linux: LinuxInitializationSettings(defaultActionName: 'Open reminder'),
        windows: WindowsInitializationSettings(
          appName: 'Maharashtra Tyres',
          appUserModelId: 'com.maharashtratyres.maharashtra_tyres',
          guid: '96cd1089-eccc-4ae8-a7e3-002a6468d108',
        ),
        web: WebInitializationSettings(),
      );

      final pluginInitialized = await _plugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      if (pluginInitialized == false) {
        throw StateError('The notification platform could not initialize.');
      }
      _initialized = true;

      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        _initialNotificationPayload =
            launchDetails?.notificationResponse?.payload;
      }
      if (await isEnabled()) {
        await _syncSavedReminders();
      }
    } catch (error, stackTrace) {
      debugPrint('Reminder notifications could not initialize: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<bool> isEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_enabledKey) ?? false;
  }

  Future<bool> setEnabled(bool enabled) async {
    if (!enabled) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_enabledKey, false);
      await _cancelAll();
      return false;
    }

    // On web this must run before other awaits so the browser recognizes the
    // permission request as coming directly from the user's button press.
    var permissionGranted = false;
    try {
      permissionGranted = await _requestPermission();
    } catch (error) {
      debugPrint('Notification permission request failed: $error');
    }
    final preferences = await SharedPreferences.getInstance();
    if (!permissionGranted) {
      await preferences.setBool(_enabledKey, false);
      await _cancelAll();
      return false;
    }

    await preferences.setBool(_enabledKey, true);
    await _syncSavedReminders();
    return true;
  }

  Future<bool> _requestPermission() async {
    if (!_initialized) return false;

    if (kIsWeb) {
      if (!WebFlutterLocalNotificationsPlugin.isSupported) return false;
      final webPlugin = _plugin.resolvePlatformSpecificImplementation<
          WebFlutterLocalNotificationsPlugin>();
      if (webPlugin == null) return false;
      if (webPlugin.permissionStatus == WebNotificationPermission.granted) {
        return true;
      }
      await webPlugin.requestNotificationsPermission();
      return webPlugin.permissionStatus == WebNotificationPermission.granted;
    }

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return await androidPlugin.requestNotificationsPermission() ?? true;
    }

    final iosPlugin =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      return await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    final macPlugin =
        _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
    if (macPlugin != null) {
      return await macPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return true;
  }

  Future<void> syncReminders(List<Map<String, dynamic>> reminders) async {
    if (!await isEnabled()) return;
    await _replaceSchedules(reminders);
  }

  Future<void> _syncSavedReminders() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_remindersKey);
    if (raw == null || raw.isEmpty) {
      await _replaceSchedules(const []);
      return;
    }

    try {
      final decoded = jsonDecode(raw) as List;
      await _replaceSchedules(
        decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList(),
      );
    } catch (error) {
      debugPrint('Could not restore reminder notifications: $error');
    }
  }

  Future<void> _replaceSchedules(List<Map<String, dynamic>> reminders) async {
    await _cancelAll();

    final now = DateTime.now();
    final scheduled = reminders
        .where((reminder) => reminder['completed'] != true)
        .map((reminder) => (reminder: reminder, dueAt: _dueAt(reminder)))
        .where((entry) => entry.dueAt != null && entry.dueAt!.isAfter(now))
        .toList()
      ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));

    // iOS keeps at most 64 pending local notifications.
    final schedulingLimit = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
        ? 60
        : scheduled.length;
    for (final entry in scheduled.take(schedulingLimit)) {
      final reminder = entry.reminder;
      final dueAt = entry.dueAt!;
      final id = _notificationId(
        reminder['id']?.toString() ??
            reminder['title']?.toString() ??
            'reminder',
      );
      final payload = jsonEncode(reminder);
      final title = reminder['title']?.toString().trim().isNotEmpty == true
          ? reminder['title'].toString()
          : 'Maharashtra Tyres reminder';
      final body = _notificationBody(reminder, dueAt);

      if (kIsWeb || defaultTargetPlatform == TargetPlatform.linux) {
        _webTimers[id] = Timer(dueAt.difference(now), () async {
          _webTimers.remove(id);
          try {
            await _plugin.show(
              id: id,
              title: title,
              body: body,
              notificationDetails: _notificationDetails(title, body),
              payload: payload,
            );
          } catch (error) {
            debugPrint('Could not display reminder notification: $error');
          }
          _showInAppPopup(reminder);
        });
      } else {
        try {
          await _plugin.zonedSchedule(
            id: id,
            title: title,
            body: body,
            scheduledDate: tz.TZDateTime.from(dueAt, tz.local),
            notificationDetails: _notificationDetails(title, body),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: payload,
          );
        } catch (error) {
          debugPrint('Could not schedule reminder notification: $error');
        }
      }
    }
  }

  Future<void> _cancelAll() async {
    for (final timer in _webTimers.values) {
      timer.cancel();
    }
    _webTimers.clear();
    if (_initialized) {
      try {
        await _plugin.cancelAll();
      } catch (error) {
        debugPrint('Could not clear reminder notifications: $error');
      }
    }
  }

  DateTime? _dueAt(Map<String, dynamic> reminder) {
    final rawDate = reminder['due_date']?.toString() ?? '';
    final date = DateTime.tryParse(rawDate);
    if (date == null) return null;

    final rawTime = (reminder['time']?.toString() ?? '')
        .replaceAll('\u202f', ' ')
        .replaceAll('.', '')
        .trim()
        .toUpperCase();
    final match = RegExp(r'^(\d{1,2}):(\d{2})(?:\s*([AP]M))?$').firstMatch(rawTime);
    if (match == null) return null;

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final meridiem = match.group(3);
    if (minute > 59) return null;
    if (meridiem != null) {
      if (hour < 1 || hour > 12) return null;
      if (meridiem == 'PM' && hour != 12) hour += 12;
      if (meridiem == 'AM' && hour == 12) hour = 0;
    } else if (hour > 23) {
      return null;
    }

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  String _notificationBody(Map<String, dynamic> reminder, DateTime dueAt) {
    final category = reminder['category']?.toString() ?? 'Reminder';
    final hour = dueAt.hour % 12 == 0 ? 12 : dueAt.hour % 12;
    final minute = dueAt.minute.toString().padLeft(2, '0');
    final meridiem = dueAt.hour < 12 ? 'AM' : 'PM';
    return '$category - ${dueAt.month}/${dueAt.day}/${dueAt.year} at $hour:$minute $meridiem';
  }

  NotificationDetails _notificationDetails(String title, String body) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Payment, stock and follow-up reminders',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
          ),
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
        macOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
        linux: const LinuxNotificationDetails(
          urgency: LinuxNotificationUrgency.critical,
          resident: true,
        ),
        windows: const WindowsNotificationDetails(
          duration: WindowsNotificationDuration.long,
        ),
        web: const WebNotificationDetails(requireInteraction: true),
      );

  int _notificationId(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  Map<String, dynamic>? takeInitialNotification() {
    final payload = _initialNotificationPayload;
    _initialNotificationPayload = null;
    return _decodePayload(payload);
  }

  Map<String, dynamic>? _decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return {'id': payload};
    }
    return null;
  }

  void _onNotificationTapped(NotificationResponse response) {
    final reminder = _decodePayload(response.payload);
    if (reminder == null) return;
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      _initialNotificationPayload = response.payload;
      return;
    }
    navigator.pushNamed('/reminders', arguments: reminder);
  }

  void _showInAppPopup(Map<String, dynamic> reminder) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;
    showDialog<void>(
      context: context,
      builder: (_) => ReminderNotificationPopup(
        reminder: reminder,
        onOpenReminder: _openReminder,
      ),
    );
  }

  void _openReminder() {
    _navigatorKey?.currentState?.pushNamed('/reminders');
  }
}
