import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRouter.home);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF1E1E1E,
      ), // Dark theme to match the beautiful new app icon!
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Styled rich text matches new app icon branding
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Bakhabar ',
                    style: AppTextStyles.h1.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'Ai',
                    style: AppTextStyles.h1.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Shehar ka Nigehban',
              style: AppTextStyles.bodyMuted.copyWith(
                fontSize: 15,
                color: Colors.white54,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
