import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/onboarding_store.dart';
import '../../utils/constants/adips_palette.dart';
import '../../utils/constants/image_strings.dart';
import '../../utils/constants/text_strings.dart';
import 'web_register_page.dart' show AuthLogo;

class _Slide {
  const _Slide(this.imageDark, this.imageLight, this.title, this.accent, this.subtitle);

  final String imageDark;
  final String imageLight;
  final String title;
  final String accent;
  final String subtitle;
}

const _slides = <_Slide>[
  _Slide(AdipsImages.onBoardingImageDark1, AdipsImages.onBoardingImageLight1,
      AdipsText.onBoardingTitle1, AdipsText.onBoardingTitle1a, AdipsText.onBoardingSubTitle1),
  _Slide(AdipsImages.onBoardingImageDark2, AdipsImages.onBoardingImageLight2,
      AdipsText.onBoardingTitle2, AdipsText.onBoardingTitle2a, AdipsText.onBoardingSubTitle2),
  _Slide(AdipsImages.onBoardingImageDark3, AdipsImages.onBoardingImageLight3,
      AdipsText.onBoardingTitle3, AdipsText.onBoardingTitle3a, AdipsText.onBoardingSubTitle3),
];

/// 3-slide intro, shown once per browser before the first login.
class WebOnboardingPage extends StatefulWidget {
  const WebOnboardingPage({super.key});

  @override
  State<WebOnboardingPage> createState() => _WebOnboardingPageState();
}

class _WebOnboardingPageState extends State<WebOnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await OnboardingStore.markSeen();
    Get.offAllNamed('/login');
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark
        ? AdipsPalette.darkPrimaryBrandText
        : AdipsPalette.lightPrimaryBrandText;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      AuthLogo(isDark: isDark),
                      const Spacer(),
                      if (!_isLast)
                        TextButton(onPressed: _finish, child: const Text('Skip')),
                    ],
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _slides.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) =>
                          _SlideView(slide: _slides[i], isDark: isDark),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _slides.length; i++)
                        GestureDetector(
                          onTap: () => _controller.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: i == _index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: i == _index ? accent : theme.colorScheme.outline,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Text(_isLast ? 'Get started' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.isDark});

  final _Slide slide;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent =
        isDark ? AdipsPalette.onboardSecondary : AdipsPalette.lightPrimaryBrandText;
    final titleStyle = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurface,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final imageHeight =
            constraints.maxHeight * 0.5 < 320 ? constraints.maxHeight * 0.5 : 320.0;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  isDark ? slide.imageDark : slide.imageLight,
                  height: imageHeight,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      SizedBox(height: imageHeight),
                ),
                const SizedBox(height: 24),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: titleStyle,
                    children: [
                      TextSpan(text: slide.title),
                      TextSpan(text: slide.accent, style: TextStyle(color: accent)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  slide.subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
