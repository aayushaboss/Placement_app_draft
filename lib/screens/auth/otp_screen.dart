import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../nav.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/back_chevron.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/responsive_body.dart';

/// Mirrors frontend/app/auth/otp.tsx (Otp).
class OtpScreen extends StatefulWidget {
  final String identifier;

  /// Only the "I already have an account" path skips onboarding.
  final bool returning;

  const OtpScreen({super.key, required this.identifier, this.returning = false});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with SingleTickerProviderStateMixin {
  final _hiddenController = TextEditingController();
  final _focusNode = FocusNode();
  String _code = '';
  String? _error;
  bool _loading = false;
  int _timer = 30;
  Timer? _countdown;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);

    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_timer > 0) setState(() => _timer--);
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _shakeController.dispose();
    _hiddenController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verify(String code) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final appState = context.read<AppState>();
    try {
      final user = await appState.verifyOtp(widget.identifier, code, returning: widget.returning);
      if (!mounted) return;
      final route = routeForUser(user);
      // Keep stack for unfinished onboarding so Back works; clear stack for home.
      if (route == '/tabs') {
        context.go(route);
      } else {
        context.push(route);
      }
    } catch (e) {
      setState(() {
        _error = e.toString().contains('expired')
            ? "That code expired — tap resend for a new one"
            : "That code's not it — give it another go";
        _code = '';
        _hiddenController.clear();
      });
      _shakeController.forward(from: 0);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.length > 6 ? digits.substring(0, 6) : digits;
    setState(() {
      _code = trimmed;
      _error = null;
    });
    if (trimmed.length == 6) _verify(trimmed);
  }

  Future<void> _resend() async {
    if (_timer > 0) return;
    await context.read<AppState>().requestOtp(widget.identifier);
    setState(() => _timer = 30);
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.blue,
        body: ResponsiveBody(child: Stack(
          children: [
            Positioned(
              left: AppSpacing.lg,
              top: topInset + AppSpacing.sm,
              child: const BackChevron(fallbackRoute: '/auth/login'),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + 72, AppSpacing.xl, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontFamily: kFontFamily,
                        color: AppColors.white,
                        fontSize: 32,
                        fontWeight: AppFontWeight.semibold,
                        height: 38 / 32,
                      ),
                      children: [
                        TextSpan(text: 'Verify your\n'),
                        TextSpan(text: 'number', style: TextStyle(color: AppColors.yellow)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Text(
                      'Enter the 6-digit code sent to ${widget.identifier}',
                      style: AppTextStyles.body.copyWith(color: AppColors.whiteA70, fontSize: 15),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => FocusScope.of(context).requestFocus(_focusNode),
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xxl),
                      child: AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(_shakeAnimation.value, 0),
                          child: child,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (i) {
                            final active = _code.length == i;
                            return Container(
                              width: 48,
                              height: 58,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.whiteA10,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                  color: _error != null
                                      ? AppColors.error
                                      : (active ? AppColors.yellow : AppColors.whiteA20),
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                i < _code.length ? _code[i] : '',
                                style: AppTextStyles.h2.copyWith(
                                  color: AppColors.white,
                                  fontSize: 24,
                                  fontWeight: AppFontWeight.medium,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: 0,
                    child: SizedBox(
                      width: 1,
                      height: 1,
                      child: TextField(
                        controller: _hiddenController,
                        focusNode: _focusNode,
                        onChanged: _onChanged,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        autofocus: true,
                        autofillHints: const [],
                        decoration: const InputDecoration(counterText: ''),
                      ),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Text(
                        _error!,
                        style: AppTextStyles.body.copyWith(color: AppColors.yellow, fontSize: 14, fontWeight: AppFontWeight.medium),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: PillButton(
                      label: 'Verify',
                      onPressed: () => _code.length == 6 ? _verify(_code) : null,
                      loading: _loading,
                      disabled: _code.length != 6,
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.lg),
                      child: GestureDetector(
                        onTap: _resend,
                        child: Text(
                          _timer > 0 ? 'Resend code in ${_timer}s' : 'Resend code',
                          style: AppTextStyles.body.copyWith(
                            color: _timer == 0 ? AppColors.yellow : AppColors.whiteA70,
                            fontSize: 14,
                            fontWeight: AppFontWeight.medium,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        )),
      ),
    );
  }
}
