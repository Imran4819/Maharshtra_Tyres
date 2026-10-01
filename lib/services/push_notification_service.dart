import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maharashtra_tyres/services/auth_service.dart';
import 'package:maharashtra_tyres/services/push_token_service.dart';
import 'package:maharashtra_tyres/services/reminder_notification_service.dart';
import 'package:maharashtra_tyres/widgets/app_navigation.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  Future<bool>? _initializing;
  Map<String, dynamic>? _initialMessageData;
  bool _initialized = false;

  Future<bool> initialize() async {
    if (_initialized) return true;
    final activeInitialization = _initializing;
    if (activeInitialization != null) return activeInitialization;

    final initialization = _initialize();
    _initializing = initialization;
    final initialized = await initialization;
    _initializing = null;
    return initialized;
  }

  Future<bool> _initialize() async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen(
        _registerRefreshedToken,
        onError: (Object error) {
          debugPrint('FCM token refresh failed: $error');
        },
      );
      _messageSubscription = FirebaseMessaging.onMessage.listen(
        _showForegroundMessage,
      );
      _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        _openFromMessage,
      );
      final initialMessage = await messaging.getInitialMessage();
      _initialMessageData = initialMessage?.data;
      _initialized = true;
      await registerIfEnabled();
      return true;
    } catch (error) {
      debugPrint('Push notifications could not initialize: $error');
      return false;
    }
  }

  /// Requests permission after a user enables notifications, then registers
  /// this installation's FCM token with the signed-in user's server account.
  Future<bool> requestPermissionAndRegister() async {
    if (!await initialize()) return false;

    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (!_permissionGranted(settings.authorizationStatus)) return false;

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return false;
      await PushTokenService.registerToken(token);
      return true;
    } catch (error) {
      debugPrint('Push notification permission or registration failed: $error');
      return false;
    }
  }

  /// Re-registers an existing, permitted installation after login or app
  /// startup. It does not trigger a permission prompt.
  Future<bool> registerIfEnabled() async {
    if (!_initialized ||
        !await ReminderNotificationService.instance.isEnabled() ||
        (await AuthService.getToken()) == null) {
      return false;
    }

    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      if (!_permissionGranted(settings.authorizationStatus)) return false;
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return false;
      await PushTokenService.registerToken(token);
      return true;
    } catch (error) {
      debugPrint('Push token registration failed: $error');
      return false;
    }
  }

  Future<void> _registerRefreshedToken(String token) async {
    if (!await ReminderNotificationService.instance.isEnabled() ||
        (await AuthService.getToken()) == null) {
      return;
    }

    try {
      await PushTokenService.registerToken(token);
    } catch (error) {
      debugPrint('Refreshed push token could not be registered: $error');
    }
  }

  Future<void> disablePushToken() async {
    if (!_initialized) return;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (error) {
      debugPrint('Push token could not be disabled on this device: $error');
    }
  }

  String? takeInitialMessageRoute() {
    final data = _initialMessageData;
    _initialMessageData = null;
    return data == null ? null : _routeFor(data);
  }

  void _showForegroundMessage(RemoteMessage message) {
    final context = appNavigatorKey.currentContext;
    if (context == null) return;

    final title =
        message.notification?.title ??
        message.data['title']?.toString() ??
        'Maharashtra Tyres';
    final body =
        message.notification?.body ??
        message.data['body']?.toString() ??
        'You have a new notification.';
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text('$title: $body'),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () => _openFromMessage(message),
        ),
      ),
    );
  }

  void _openFromMessage(RemoteMessage message) {
    final route = _routeFor(message.data);
    appNavigatorKey.currentState?.pushNamed(route);
  }

  String _routeFor(Map<String, dynamic> data) {
    const routes = {
      '/dashboard',
      '/bills',
      '/customers',
      '/inventory',
      '/invoices',
      '/reminders',
      '/sales',
      '/settings',
    };
    final requestedRoute = data['route']?.toString();
    return routes.contains(requestedRoute) ? requestedRoute! : '/dashboard';
  }

  bool _permissionGranted(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _messageOpenedSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _messageSubscription = null;
    _messageOpenedSubscription = null;
  }
}
