import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hesba/core/theme/app_theme.dart';

class AuthFooter extends StatelessWidget {
  final String questionText;
  final String actionText;
  final VoidCallback onAction;

  const AuthFooter({
    super.key,
    required this.questionText,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          questionText,
          style: GoogleFonts.cairo(color: Colors.grey),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(
            actionText,
            style: GoogleFonts.cairo(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
