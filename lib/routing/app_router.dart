import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';
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

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final user = authState.value;

      final isSplash = state.matchedLocation == '/splash';
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';

      if (isLoading) {
        return isSplash ? null : '/splash';
      }

      if (user == null) {
        if (isLoggingIn || isRegistering) return null;
        return '/login';
      }

      // User logged in
      if (isSplash || isLoggingIn) {
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
        builder: (context, state) {
          final customer = state.extra as Customer;
          return CustomerDetailScreen(customer: customer);
        },
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
        builder: (context, state) {
          final job = state.extra as Job;
          return JobDetailScreen(job: job);
        },
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
});
