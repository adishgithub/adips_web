import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('Page not found', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('The page you are looking for does not exist.',
                  textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Get.offAllNamed('/dashboard'),
                child: const Text('Go to dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
