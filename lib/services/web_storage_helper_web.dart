// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

void saveTokenToWebStorage(String token) {
  try {
    html.window.localStorage['token'] = token;
    html.window.localStorage['auth_token'] = token;
    html.window.sessionStorage['token'] = token;
    html.window.sessionStorage['auth_token'] = token;
  } catch (e) {
    // Silently ignore storage errors if cookies/storage are disabled
  }
}

void clearTokenFromWebStorage() {
  try {
    html.window.localStorage.remove('token');
    html.window.localStorage.remove('auth_token');
    html.window.sessionStorage.remove('token');
    html.window.sessionStorage.remove('auth_token');
  } catch (e) {
    // Silently ignore storage errors
  }
}
