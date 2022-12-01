import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/user.dart';

const REFRESH_TOKEN_KEY = '';
const BACKEND_TOKEN_KEY = '';

const GOOGLE_CLIENT_ID_IOS =
    '543660397854-qobpehta8eajd750gr4f4n0cv1n23m3s.apps.googleusercontent.com';
const GOOGLE_REDIRECT_URI_IOS =
    'com.googleusercontent.apps.543660397854-qobpehta8eajd750gr4f4n0cv1n23m3s:/api/v1/auth/callbacks/sign-in-with-google';

const GOOGLE_CLIENT_ID_ANDROID =
    '543660397854-h1sodc8t5htp81k9lihs00kojdnrupfe.apps.googleusercontent.com';
const GOOGLE_REDIRECT_URI_ANDROID =
    'com.googleusercontent.apps.543660397854-h1sodc8t5htp81k9lihs00kojdnrupfe:/api/v1/auth/callbacks/sign-in-with-google';

const GOOGLE_CLIENT_ID_WEB =
    '543660397854-v1uqg977aqbgtq4g0n1gl6tbc0ur5vf3.apps.googleusercontent.com';
const GOOGLE_REDIRECT_URI_WEB =
    'com.googleusercontent.apps.543660397854-h1sodc8t5htp81k9lihs00kojdnrupfe:/api/v1/auth/callbacks/sign-in-with-google';

const GOOGLE_ISSUER = 'https://accounts.google.com';
const APPLE_ISSUER = 'https://apple.com';

String clientId() {
  if (kIsWeb) {
    return GOOGLE_CLIENT_ID_WEB;
  }
  if (Platform.isAndroid) {
    return GOOGLE_CLIENT_ID_ANDROID;
  } else if (Platform.isIOS) {
    return GOOGLE_CLIENT_ID_IOS;
  }
  return '';
}

String redirectUrl() {
  if (kIsWeb) {
    return GOOGLE_REDIRECT_URI_WEB;
  }
  if (Platform.isAndroid) {
    return GOOGLE_REDIRECT_URI_ANDROID;
  } else if (Platform.isIOS) {
    return GOOGLE_REDIRECT_URI_IOS;
  }
  return '';
}

class AuthService {
  static final AuthService instance = AuthService._();
  factory AuthService() => instance;
  AuthService._();

  final appAuth = const FlutterAppAuth();

  Future<bool> initAuth() async {
    final storage = await SharedPreferences.getInstance();
    final storedRefreshToken = storage.getString(REFRESH_TOKEN_KEY);
    final TokenResponse? result;

    if (storedRefreshToken == null) {
      return false;
    }

    try {
      // Obtaining token response from refresh token
      result = await appAuth.token(
        TokenRequest(
          clientId(),
          redirectUrl(),
          issuer: GOOGLE_ISSUER,
          refreshToken: storedRefreshToken,
        ),
      );

      final bool setResult = await _handleAuthResult(result);
      return setResult;
    } catch (e, s) {
      print('error on Refresh Token: $e - stack: $s');
      // logOut() possibly
      return false;
    }
  }

  Future<bool> login(String issuer) async {
    final AuthorizationTokenRequest authorizationTokenRequest;

    try {
      authorizationTokenRequest = AuthorizationTokenRequest(
        clientId(),
        redirectUrl(),
        issuer: issuer,
        scopes: ['email'],
      );

      // Requesting the auth token and waiting for the response
      final AuthorizationTokenResponse? result =
          await appAuth.authorizeAndExchangeCode(
        authorizationTokenRequest,
      );

      // Taking the obtained result and processing it
      return await _handleAuthResult(result);
    } on PlatformException {
      print("User has cancelled or no internet!");
      return false;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> logout() async {
    final storage = await SharedPreferences.getInstance();
    await storage.remove(REFRESH_TOKEN_KEY);
    return true;
  }

  Future<bool> _handleAuthResult(result) async {
    final bool isValidResult =
        result != null && result.accessToken != null && result.idToken != null;
    if (isValidResult) {
      final storage = await SharedPreferences.getInstance();

      // Storing refresh token to renew login on app restart
      if (result.refreshToken != null) {
        await storage.setString(REFRESH_TOKEN_KEY, result.refreshToken);
      }

      final user =
          await NewSource.signInUserGoogle(result.idToken, result.accessToken);

      if (user.id != 0) {
        user.storeUser();
        User.current = user;
        return true;
      }
    }
    return false;
  }
}
