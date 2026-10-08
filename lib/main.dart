import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase Connection
  await SupabaseService.initialize();

  runApp(
    const SessionScope(
      child: NewBharatTyreRemouldApp(),
    ),
  );
}

/// Owns the [ProviderScope]. When the user signs out the scope is thrown away and
/// recreated, so no cached data (jobs, invoices, ledgers...) of the previous user can
/// show up for the next person who signs in on the same device.
class SessionScope extends StatefulWidget {
  final Widget child;

  const SessionScope({super.key, required this.child});

  @override
  State<SessionScope> createState() => _SessionScopeState();
}

class _SessionScopeState extends State<SessionScope> {
  Key _scopeKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    sessionResetNotifier.addListener(_reset);
  }

  void _reset() {
    if (mounted) setState(() => _scopeKey = UniqueKey());
  }

  @override
  void dispose() {
    sessionResetNotifier.removeListener(_reset);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(key: _scopeKey, child: widget.child);
  }
}

class NewBharatTyreRemouldApp extends ConsumerWidget {
  const NewBharatTyreRemouldApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
