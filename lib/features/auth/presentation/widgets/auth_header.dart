import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hesba/core/theme/app_theme.dart';

class AuthHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const AuthHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 60, color: AppTheme.primaryColor),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey),
          ),
        ],
      ],
    );
  }
}
