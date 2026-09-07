import 'package:flutter/material.dart';

/// A shared scaffold wrapper for the profile sub-screens,
/// adapting automatically to light / dark theme.
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        actions: actions,
      ),
      body: body,
    );
  }
}
