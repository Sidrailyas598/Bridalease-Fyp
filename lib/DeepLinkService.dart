import '''
package:app_links/app_links.dart''';

import 'package:bridalease_fyp/screens/login_screen.dart';
import 'package:flutter/material.dart';


class DeepLinkService {
  static Future<void> initDeepLinks(BuildContext context) async {
    try {
      final appLinks = AppLinks();

      // App running & deep link comes
      appLinks.uriLinkStream.listen((uri) {
        _processDeepLink(uri, context);
            });

      // App closed → opened by deep link
      final initialUri = await appLinks.getInitialLink();
      if (initialUri != null) {
        _processDeepLink(initialUri, context);
      }
    } catch (e) {
      print("Deep Link Error: $e");
    }
  }

  static void _processDeepLink(Uri uri, BuildContext context) {
    print("Processing Deep Link: $uri");

    if (uri.path.contains("email-verified")) {
      // Go to login screen after verification
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    } else if (uri.path.contains("update-password")) {
      // Go to update password screen
      // Navigator.pushAndRemoveUntil(
      //   context,
      //   MaterialPageRoute(builder: (_) => UpdatePasswordScreen()),
      //   (route) => false,
      // );
    }
  }
}
