import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/toast_service.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

class TeacherApp extends ConsumerWidget {
  const TeacherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Teacher App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
    );
  }
}
