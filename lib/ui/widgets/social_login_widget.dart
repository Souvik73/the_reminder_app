import 'package:flutter/material.dart';

class SocialLoginWidget extends StatelessWidget {
  final VoidCallback onGooglePressed;
  final VoidCallback? onApplePressed;
  final bool isLoading;

  const SocialLoginWidget({
    super.key,
    required this.onGooglePressed,
    this.onApplePressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Google Sign In Button
        _buildSocialButton(
          onPressed: isLoading ? null : onGooglePressed,
          icon: 'assets/images/google_logo.png', // Add Google logo asset
          text: 'Continue with Google',
          backgroundColor: Colors.white,
          textColor: const Color(0xFF2D3748),
          borderColor: Colors.grey[300]!,
        ),

        // Apple Sign In Button (iOS only)
        if (onApplePressed != null) ...[
          const SizedBox(height: 16),
          _buildSocialButton(
            onPressed: isLoading ? null : onApplePressed!,
            icon: 'assets/images/apple_logo.png', // Add Apple logo asset
            text: 'Continue with Apple',
            backgroundColor: Colors.black,
            textColor: Colors.white,
            borderColor: Colors.black,
          ),
        ],
      ],
    );
  }

  Widget _buildSocialButton({
    required VoidCallback? onPressed,
    required String icon,
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required Color borderColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use network image or asset image based on your preference
            SizedBox(
              width: 24,
              height: 24,
              child: icon.contains('google')
                  ? Image.network(
                      'https://developers.google.com/identity/images/g-logo.png',
                      width: 24,
                      height: 24,
                    )
                  : Icon(Icons.apple, color: textColor, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
