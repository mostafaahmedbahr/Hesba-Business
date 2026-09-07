import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? actions;
  final bool showAvatar;

  const MainAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showAvatar = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 0.h);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        if (showAvatar)
          Padding(
            padding: EdgeInsets.only(left: 12.w),
            child: Container(
              width: 38.w,
              height: 38.w,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Color(0xFF1A4FD6),
                size: 22,
              ),
            ),
          ),
        if (actions != null) ...[actions!],
      ],
    );
  }
}
