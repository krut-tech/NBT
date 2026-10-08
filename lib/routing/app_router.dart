import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/customers/providers/customer_provider.dart';
import '../features/jobs/providers/job_provider.dart';
import '../features/auth/views/login_screen.dart';
import '../features/auth/views/register_screen.dart';
import '../features/auth/views/splash_screen.dart';
import '../features/cold_chamber/views/cold_chamber_screen.dart';
import '../features/customer_portal/views/customer_portal_dashboard.dart';
import '../features/customers/models/customer.dart';
import '../features/customers/views/customer_detail_screen.dart';
import '../features/customers/views/customer_form_screen.dart';
import '../features/customers/views/customer_list_screen.dart';
import '../features/dashboard/views/admin_dashboard.dart';
import '../features/delivery/views/delivery_screen.dart';
import '../features/invoices/views/invoice_form_screen.dart';
import '../features/invoices/views/invoice_list_screen.dart';
import '../features/jobs/models/job.dart';
import '../features/jobs/views/job_detail_screen.dart';
import '../features/jobs/views/job_form_screen.dart';
import '../features/jobs/views/job_list_screen.dart';
import '../features/jobs/views/qr_scanner_screen.dart';
import '../features/ledger/views/ledger_screen.dart';
import '../features/master_data/views/master_data_screen.dart';
import '../features/notifications/views/notification_center_screen.dart';
import '../features/payments/views/payment_form_screen.dart';
import '../features/payments/views/payment_list_screen.dart';
import '../features/production/views/production_list_screen.dart';
import '../features/qc/views/qc_screen.dart';
import '../features/reports/views/analytics_screen.dart';
import '../features/reports/views/reports_screen.dart';
import '../features/staff/views/staff_list_screen.dart';
import '../features/stock/views/stock_list_screen.dart';
import '../features/stock/views/stock_transaction_screen.dart';
import '../features/suppliers/views/supplier_list_screen.dart';

/// Screens a customer account may open. Everything else is staff-only (the database
/// enforces this with RLS as well; this just keeps customers out of empty/forbidden UIs).
bool _customerMayOpen(String location) {
  const exact = {'/dashboard', '/notifications', '/ledger', '/payments'};
  if (exact.contains(location)) return true;
  return location.startsWith('/jobs/') && location != '/jobs/new';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // The router must be created ONCE. Watching the auth state here would rebuild the
  // whole GoRouter on every auth change, which resets navigation and throws away the
  // login form (and its error message). Instead the router is told to re-run its
  // redirect whenever the auth state changes.
  final authChanged = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, __) => authChanged.value++);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: authChanged,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoading = authState.isLoading;
      final user = authState.valueOrNull;

      final location = state.matchedLocation;
      final isSplash = location == '/splash';
      final isLoggingIn = location == '/login';
      final isRegistering = location == '/register';

      if (isLoading) {
        return isSplash ? null : '/splash';
      }

      if (user == null) {
        if (isLoggingIn || isRegistering) return null;
        return '/login';
      }

      // User logged in
      if (isSplash || isLoggingIn || isRegistering) {
        return '/dashboard';
      }

      if (user.isCustomer && !_customerMayOpen(location)) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) {
          final user = ref.read(authProvider).value;
          if (user != null && user.isCustomer) {
            return const CustomerPortalDashboard();
          }
          return const AdminDashboard();
        },
      ),

      // Customers
      GoRoute(
        path: '/customers',
        builder: (context, state) => const CustomerListScreen(),
      ),
      GoRoute(
        path: '/customers/new',
        builder: (context, state) => const CustomerFormScreen(),
      ),
      GoRoute(
        path: '/customers/edit',
        builder: (context, state) {
          final customer = state.extra as Customer?;
          return CustomerFormScreen(customer: customer);
        },
      ),
      GoRoute(
        path: '/customers/:id',
        builder: (context, state) => _CustomerRoute(
          id: state.pathParameters['id']!,
          customer: state.extra is Customer ? state.extra as Customer : null,
        ),
      ),

      // Jobs
      GoRoute(
        path: '/jobs',
        builder: (context, state) => const JobListScreen(),
      ),
      GoRoute(
        path: '/jobs/new',
        builder: (context, state) {
          final preselectedCustomer = state.extra as Customer?;
          return JobFormScreen(preselectedCustomer: preselectedCustomer);
        },
      ),
      GoRoute(
        path: '/jobs/:id',
        builder: (context, state) => _JobRoute(
          id: state.pathParameters['id']!,
          job: state.extra is Job ? state.extra as Job : null,
        ),
      ),
      GoRoute(
        path: '/qr-scanner',
        builder: (context, state) => const QrScannerScreen(),
      ),

      // Modules
      GoRoute(
        path: '/production',
        builder: (context, state) => const ProductionListScreen(),
      ),
      GoRoute(
        path: '/cold-chamber',
        builder: (context, state) => const ColdChamberScreen(),
      ),
      GoRoute(
        path: '/qc',
        builder: (context, state) => const QcScreen(),
      ),
      GoRoute(
        path: '/delivery',
        builder: (context, state) => const DeliveryScreen(),
      ),

      // Invoices & Payments
      GoRoute(
        path: '/invoices',
        builder: (context, state) => const InvoiceListScreen(),
      ),
      GoRoute(
        path: '/invoices/new',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return InvoiceFormScreen(
              initialCustomerId: extra?['customerId'] as String?);
        },
      ),
      GoRoute(
        path: '/payments',
        builder: (context, state) => const PaymentListScreen(),
      ),
      GoRoute(
        path: '/payments/new',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PaymentFormScreen(initialData: extra);
        },
      ),
      GoRoute(
        path: '/ledger',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return LedgerScreen(
              initialCustomerId: extra?['customerId'] as String?);
        },
      ),

      // Stock & Suppliers
      GoRoute(
        path: '/stock',
        builder: (context, state) => const StockListScreen(),
      ),
      GoRoute(
        path: '/stock/transactions',
        builder: (context, state) => const StockTransactionScreen(),
      ),
      GoRoute(
        path: '/suppliers',
        builder: (context, state) => const SupplierListScreen(),
      ),

      // Notifications & Reports
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationCenterScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/reports/analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),

      // Settings
      GoRoute(
        path: '/master-data',
        builder: (context, state) => const MasterDataScreen(),
      ),
      GoRoute(
        path: '/staff',
        builder: (context, state) => const StaffListScreen(),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    authChanged.dispose();
  });

  return router;
});

/// Job detail that also works when the screen is opened without the `extra` object
/// (page refresh on web, deep link): the job is then loaded by its id.
class _JobRoute extends ConsumerWidget {
  final String id;
  final Job? job;

  const _JobRoute({required this.id, this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final known = job;
    if (known != null) return JobDetailScreen(job: known);

    return ref.watch(jobByIdProvider(id)).when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => Scaffold(
            appBar: AppBar(title: const Text('Job')),
            body: const Center(child: Text('Job not found.')),
          ),
          data: (loaded) => JobDetailScreen(job: loaded),
        );
  }
}

/// Same idea for the customer detail screen.
class _CustomerRoute extends ConsumerWidget {
  final String id;
  final Customer? customer;

  const _CustomerRoute({required this.id, this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final known = customer;
    if (known != null) return CustomerDetailScreen(customer: known);

    return ref.watch(customerProvider).when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Scaffold(
            appBar: AppBar(title: const Text('Customer')),
            body: Center(child: Text('Could not load customer: $e')),
          ),
          data: (customers) {
            final match = customers.where((c) => c.id == id).firstOrNull;
            if (match == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Customer')),
                body: const Center(child: Text('Customer not found.')),
              );
            }
            return CustomerDetailScreen(customer: match);
          },
        );
  }
}
