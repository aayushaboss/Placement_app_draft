import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Small circular percent-complete indicator — extracted out of
/// home_dashboard_cards.dart so the Profile tab's header can reuse it with
/// its own on-blue palette instead of a second hand-pasted copy.
class ProgressRing extends StatelessWidget {
  final int percent;
  final double size;
  final Color background;
  final Color valueColor;
  final Color textColor;

  const ProgressRing({
    super.key,
    required this.percent,
    this.size = 52,
    this.background = AppColors.white,
    this.valueColor = AppColors.blue,
    this.textColor = AppColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: percent / 100,
              strokeWidth: 4,
              backgroundColor: background,
              valueColor: AlwaysStoppedAnimation(valueColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text('$percent%', style: AppTextStyles.caption.copyWith(color: textColor, fontSize: 11, fontWeight: AppFontWeight.bold)),
        ],
      ),
    );
  }
}
