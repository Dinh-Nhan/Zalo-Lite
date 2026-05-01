import 'package:flutter/material.dart';
import 'package:frontend/apps/app_locale.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/utils/app_localizations.dart';

class ConfirmPhoneSheet extends StatelessWidget {
  final String phone;
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  const ConfirmPhoneSheet({
    super.key,
    required this.phone,
    required this.onContinue,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations(localeNotifier.value);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWideScreen = screenWidth > 600;

    // Responsive width: mobile ~85%, tablet/desktop capped
    final dialogWidth = isWideScreen
        ? (screenWidth * 0.35).clamp(340.0, 420.0)
        : (screenWidth * 0.82).clamp(280.0, 360.0);

    // Responsive font sizes
    final titleSize = isWideScreen ? 16.0 : 16.0;
    final descSize = isWideScreen ? 14.0 : 14.0;
    final buttonSize = isWideScreen ? 16.0 : 15.0;
    final verticalPadding = isWideScreen ? 28.0 : 22.0;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.4,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// TITLE + DESCRIPTION
              Padding(
                padding: EdgeInsets.fromLTRB(24, verticalPadding, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${t.get('confirmPhoneTitle')}\n$phone",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: titleSize,
                        color: AppColors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t.get('confirmPhoneDesc'),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: descSize,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: verticalPadding),
              const Divider(height: 1, color: AppColors.divider),

              /// BUTTON CONTINUE
              InkWell(
                onTap: onContinue,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: isWideScreen ? 16 : 14,
                  ),
                  child: Center(
                    child: Text(
                      t.get('continue_'),
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: buttonSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const Divider(height: 1, color: AppColors.divider),

              /// BUTTON CHANGE NUMBER
              InkWell(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                onTap: onCancel,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: isWideScreen ? 16 : 14,
                  ),
                  child: Center(
                    child: Text(
                      t.get('changeNumber'),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: buttonSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}