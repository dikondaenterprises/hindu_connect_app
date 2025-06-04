import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';

import 'firebase_options.dart';
import 'app.dart';
import 'services/local_search_service.dart';
import 'services/rating_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Stripe.publishableKey = 'pk_test_YOUR_PUBLISHABLE_KEY'; // Replace with real key

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  runZonedGuarded(() {
    runApp(const MyApp());
  }, FirebaseCrashlytics.instance.recordError);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final InAppReview _inAppReview = InAppReview.instance;
  int _launchCount = 0;
  bool _isInitialized = false;
  String? _initialLink;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Wait for at least 5 seconds while doing actual work
      await Future.wait([
        Future.delayed(const Duration(seconds: 5)),
        LocalSearchService.instance.init(),
        _handleInitialDynamicLink(),
        _incrementLaunchCountAndMaybePrompt(),
      ]);

      RatingService.promptIfAppropriate(androidLaunches: 5);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  Future<void> _handleInitialDynamicLink() async {
    final data = await FirebaseDynamicLinks.instance.getInitialLink();
    _initialLink = data?.link.toString();

    FirebaseDynamicLinks.instance.onLink.listen((PendingDynamicLinkData data) {
      _handleDynamicLink(data.link.toString());
    });
  }

  void _handleDynamicLink(String? link) {
    if (link == null || !mounted) return;

    final uri = Uri.parse(link);
    final file = uri.queryParameters['file'];
    final video = uri.queryParameters['video'];
    final temple = uri.queryParameters['temple'];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (file != null) {
        Navigator.pushNamed(context, '/viewer', arguments: file);
      } else if (video != null) {
        Navigator.pushNamed(context, '/connect', arguments: video);
      } else if (temple != null) {
        Navigator.pushNamed(context, '/temple', arguments: temple);
      }
    });
  }

  Future<void> _incrementLaunchCountAndMaybePrompt() async {
    final prefs = await SharedPreferences.getInstance();
    _launchCount = (prefs.getInt('launchCount') ?? 0) + 1;
    await prefs.setInt('launchCount', _launchCount);

    final never = prefs.getBool('neverRate') ?? false;
    final available = await _inAppReview.isAvailable();

    if (!mounted) return;

    if (!never && _launchCount == 5 && available) {
      _showRatingDialog();
    }
  }

  void _showRatingDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('⭐ Enjoying the App?'),
          content: const Text('Please rate us on Google Play!'),
          actions: [
            TextButton(
              child: const Text('Later'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Never'),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('neverRate', true);
                if (!mounted) return;
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              child: const Text('Rate Now'),
              onPressed: () {
                _inAppReview.openStoreListing();
                if (!mounted) return;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AnimatedSplashScreen(),
      );
    }

    return HinduConnectApp(initialLink: _initialLink);
  }
}

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeIn,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Replace with your asset logo
              Image.asset(
                'assets/logo.png',
                height: 120,
              ),
              const SizedBox(height: 20),
              const Text(
                'Hindu Connect',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
