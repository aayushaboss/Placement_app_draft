import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../nav.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/no_orphan.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/responsive_body.dart';

const _heroImage = 'assets/images/landing-hero.png';

/// Single landing + auth screen — replaces the old value-slides carousel,
/// segment picker, and the first half of the old profile quiz all at once.
/// One hero, a 2-line JTBD headline, Google/Email auth, and a stat line
/// instead of a logo strip — value prop, auth, and social proof in one
/// screen instead of three.
///
/// Full-bleed hero blending into the content below via a gradient scrim,
/// instead of a photo floating as a rounded card on a flat color field —
/// the "card pasted onto a background with a big empty gap under it" read
/// as unfinished rather than designed.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  bool _googleLoading = false;

  Future<void> _continueWithGoogle() async {
    if (_googleLoading) return;
    setState(() => _googleLoading = true);
    HapticFeedback.mediumImpact();
    try {
      final appState = context.read<AppState>();
      final user = await appState.mockGoogleSignIn();
      if (!mounted) return;
      context.go(routeForUser(user));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  // No `mode` query param — LoginScreen's own default (startOnEmail: false,
  // per router.dart) is the phone field, so this lands there directly
  // instead of on email.
  void _continueWithPhone() => context.push('/auth/login');

  void _goToReturningLogin() => context.push('/auth/login?returning=1');

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.blue,
        body: ResponsiveBody(child: Column(
          children: [
            // Bleeds under the status bar on purpose — an immersive,
            // edge-to-edge hero instead of a photo inset with margins on
            // every side, with a scrim fading it straight into the panel
            // below so there's no hard seam between "photo" and "content".
            SizedBox(
              height: screenHeight * 0.5,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(_heroImage, fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.blue],
                        stops: [0.55, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
                color: AppColors.blue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Manual break at a natural word boundary — letting this
                    // wrap on its own risks an orphaned word alone on its own
                    // line at most screen widths.
                    Text(
                      'Your future job\nis looking for you too.',
                      style: AppTextStyles.h1.copyWith(color: AppColors.white, fontSize: 30, fontWeight: AppFontWeight.extrabold, height: 34 / 30),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        noOrphan('Internships and jobs curated just for you.'),
                        style: AppTextStyles.bodyLg.copyWith(color: AppColors.whiteA70, fontSize: 15),
                      ),
                    ),
                    // Centered in the remaining space below the subtitle
                    // (equal slack above and below) instead of anchored
                    // right beneath it with all the leftover room pushed to
                    // the very bottom of the screen.
                    const Spacer(),
                    PillButton(
                      label: 'Continue with Google',
                      // Google's "G" has its own yellow segment, which
                      // vanishes against the yellow CTA background — a
                      // white badge behind it keeps the mark legible.
                      iconWidget: Container(
                        decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                        padding: const EdgeInsets.all(1),
                        child: SvgPicture.asset('assets/icons/google.svg'),
                      ),
                      loading: _googleLoading,
                      onPressed: _continueWithGoogle,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: PillButton(
                        label: 'Continue with Phone Number',
                        variant: PillVariant.outlineWhite,
                        icon: Ionicons.call_outline,
                        onPressed: _continueWithPhone,
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: GestureDetector(
                          onTap: _goToReturningLogin,
                          child: Text(
                            noOrphan('Already have an account? Log in'),
                            style: AppTextStyles.body.copyWith(color: AppColors.white, fontSize: 14, fontWeight: AppFontWeight.medium),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            // Stat bar removed for now — left as empty space at the bottom
            // of the blue panel (via the Spacer above) rather than filled
            // with a placeholder.
            SizedBox(height: bottomInset + AppSpacing.lg),
          ],
        )),
      ),
    );
  }
}
