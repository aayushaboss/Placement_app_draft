import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import '../utils/initials.dart';

/// Mirrors frontend/src/components/HomeHeader.tsx.
/// Pure presentational — navigation/auth data comes in via params + callbacks,
/// not pulled from router/context directly.
class HomeHeader extends StatelessWidget {
  final String? name;
  final String? subtitle;
  final bool unread;
  final String? photoUrl;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onBellTap;
  /// Search moved off the feed itself (its own dedicated screen now, not an
  /// inline bar) — only the college flow wires this in, so it's optional
  /// rather than always rendering a dead icon on the school header too.
  final VoidCallback? onSearchTap;

  /// Opens the opportunity filter — college-only, same reasoning as
  /// [onSearchTap] (school's HomeHeader usage passes nothing here, so no
  /// icon renders there). Rendered next to the search icon since college
  /// Home has no inline search bar of its own to put a filter icon beside
  /// the way the Courses tab does.
  final VoidCallback? onFilterTap;

  /// Whether a filter is currently active — swaps the icon to its filled
  /// glyph + blue tint, same "active" treatment already used for the
  /// Courses tab's own filter icon, rather than inverting the button's
  /// fill (no other icon-only button in the app does that).
  final bool isFiltering;

  const HomeHeader({
    super.key,
    this.name,
    this.subtitle,
    this.unread = true,
    this.photoUrl,
    this.onAvatarTap,
    this.onBellTap,
    this.onSearchTap,
    this.onFilterTap,
    this.isFiltering = false,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.only(
        top: topInset + AppSpacing.xs,
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        // xl (20), not the old sm (6) — this header sits directly above an
        // Expanded scrollable with nothing else providing clearance, so its
        // own bottom inset is the only thing standing between it and
        // whatever scrolls up underneath (see college_feed_screen.dart /
        // school_home_screen.dart, which no longer add their own spacer for
        // this — one shared fix instead of two inconsistent ones).
        bottom: AppSpacing.xl,
      ),
      // A flat Row, not two nested ones — the greeting block used to be its
      // own Row sized to its own intrinsic (unbounded) text width, sitting
      // next to the icon Row inside an outer `spaceBetween`. Neither side
      // was ever told to shrink, so on a narrow-enough phone the greeting
      // text alone could exceed the space left after the avatar, and
      // `spaceBetween` pushed the entire icon cluster (search/filter/bell)
      // past the right edge of the screen instead of visibly overflowing —
      // they just silently weren't there. Wrapping the greeting text in
      // Expanded (with an ellipsis) makes it the one flexible element:
      // avatar and icons keep their fixed size and stay on-screen always,
      // and a long name truncates instead of displacing them.
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: ClipOval(
              child: Container(
                width: 44,
                height: 44,
                color: AppColors.blue,
                alignment: Alignment.center,
                child: photoUrl != null
                    ? Image.network(photoUrl!, width: 44, height: 44, fit: BoxFit.cover)
                    : Text(
                        initialsFor(name),
                        style: AppTextStyles.bodyLg.copyWith(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: AppFontWeight.semibold,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  subtitle ?? 'Welcome back',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.gray500,
                    fontSize: 13,
                    fontWeight: AppFontWeight.medium,
                  ),
                ),
                Text(
                  name ?? 'Student',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              // 40px, not the avatar's 44px, with a tighter 6px gap between
              // them (was AppSpacing.sm/8px) — these three are pure utility
              // glyphs, not identity markers like the avatar, so shrinking
              // them and pulling them closer together reads as one
              // deliberate cluster of actions instead of three separate
              // large targets competing with the avatar+greeting block for
              // weight. Still comfortably above this app's own smallest
              // established tap target (the 40px boost-tip CTA in
              // home_dashboard_cards.dart).
              if (onSearchTap != null) ...[
                GestureDetector(
                  onTap: onSearchTap,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.offWhite, shape: BoxShape.circle),
                    child: const Icon(Ionicons.search_outline, size: 20, color: AppColors.ink),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (onFilterTap != null) ...[
                GestureDetector(
                  onTap: onFilterTap,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: AppColors.offWhite, shape: BoxShape.circle),
                        child: Icon(
                          isFiltering ? Ionicons.options : Ionicons.options_outline,
                          size: 20,
                          color: isFiltering ? AppColors.blue : AppColors.ink,
                        ),
                      ),
                      // Permanent, not a one-time nudge — unlike the bell's
                      // red "unread" dot, this isn't flagging something new
                      // to check out; it's a standing reminder that Home is
                      // always showing results scoped to the user's own
                      // roles, so it stays exactly like this for as long as
                      // that's true (i.e. always, once onboarded).
                      Positioned(
                        // Same (top, right) as the bell's own dot below —
                        // both sit on an identical 40x40 button, so matching
                        // offsets is what makes them read as level with each
                        // other across the row, not just individually placed.
                        top: 9,
                        right: 10,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: AppColors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.offWhite, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
              ],
              GestureDetector(
                onTap: onBellTap,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(color: AppColors.offWhite, shape: BoxShape.circle),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Center(child: Icon(Ionicons.notifications_outline, size: 22, color: AppColors.ink)),
                      if (unread)
                        Positioned(
                          // Scaled down from the old 44px circle's (11, 12)
                          // offset to match this button's smaller 40px size
                          // — otherwise the dot drifts toward the edge
                          // instead of sitting on the icon's shoulder.
                          top: 9,
                          right: 10,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.offWhite, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
