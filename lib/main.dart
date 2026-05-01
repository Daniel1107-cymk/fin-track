import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/database/database_service.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'features/security/app_lifecycle_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.seedData();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.dark;

    return AppLifecycleObserver(
      child: MaterialApp.router(
        title: 'Fin Track',
        debugShowCheckedModeBanner: false,
        themeMode: themeMode,
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            surface: AppColors.surface,
            error: AppColors.danger,
          ),
        ),
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF5F5F7),
          textTheme: GoogleFonts.dmSansTextTheme(ThemeData.light().textTheme),
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            surface: Colors.white,
            error: AppColors.danger,
          ),
        ),
        routerConfig: router,
      ),
    );
  }
}
