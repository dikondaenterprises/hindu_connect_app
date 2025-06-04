// lib/services/rating_service.dart
import 'dart:io' show Platform;
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RatingService {
  static final _review = InAppReview.instance;

  /// Call this at app start (after routing) to maybe prompt.
  static Future<void> promptIfAppropriate({int androidLaunches = 5}) async {
    final prefs = await SharedPreferences.getInstance();
    final never = prefs.getBool('neverRate') ?? false;
    if (never) return;

    final isAvailable = await _review.isAvailable();
    final launches = (prefs.getInt('launchCount') ?? 0) + 1;
    await prefs.setInt('launchCount', launches);

    // iOS: prompt immediately on first eligible call, then never again
    if (Platform.isIOS) {
      final prompted = prefs.getBool('iosPrompted') ?? false;
      if (!prompted && isAvailable) {
        await _review.requestReview(); // SKStoreReviewController
        await prefs.setBool('iosPrompted', true);
      }
      return;
    }

    // Android: prompt after androidLaunches
    if (Platform.isAndroid && launches >= androidLaunches && isAvailable) {
      await _review.requestReview();
      // After prompting, reset counter so it can re‑appear after another interval
      await prefs.setInt('launchCount', 0);
    }
  }

  /// If user chooses “Never”, call this to suppress future prompts
  static Future<void> setNeverAsk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('neverRate', true);
  }

  /// Always safe fallback to open store page
  static Future<void> openStoreListing() => _review.openStoreListing();
}
