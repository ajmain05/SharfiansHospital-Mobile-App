import 'package:go_router/go_router.dart';

import '../../features/events/screens/event_check_status_screen.dart';
import '../../features/events/screens/event_detail_screen.dart';
import '../../features/events/screens/event_registration_screen.dart';
import '../../features/events/screens/event_status_screen.dart';
import '../../features/events/screens/events_list_screen.dart';
import '../../features/bank_details/screens/bank_details_screen.dart';
import '../../features/career/screens/career_screen.dart';
import '../../features/faq/screens/faq_screen.dart';
import '../../features/gallery/screens/gallery_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/investor_auth/screens/investor_login_screen.dart';
import '../../features/investor_dashboard/screens/investor_dashboard_screen.dart';
import '../../features/investor_registration/screens/investor_registration_screen.dart';
import '../../features/admin_auth/screens/staff_login_screen.dart';
import '../../features/event_scanner/screens/event_scanner_screen.dart';
import '../../features/event_dashboard/screens/live_event_dashboard_screen.dart';
import '../../features/admin_dashboard/screens/staff_dashboard_screen.dart';
import '../../features/admin_dashboard/screens/staff_approvals_screen.dart';
import '../../features/admin_dashboard/screens/staff_directory_screen.dart';
import '../storage/local_storage.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/gallery',
      builder: (context, state) => const GalleryScreen(),
    ),
    GoRoute(path: '/faq', builder: (context, state) => const FaqScreen()),
    GoRoute(
      path: '/bank-details',
      builder: (context, state) => const BankDetailsScreen(),
    ),
    GoRoute(path: '/career', builder: (context, state) => const CareerScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const InvestorRegistrationScreen(),
    ),
    GoRoute(
      path: '/investor/login',
      builder: (context, state) => const InvestorLoginScreen(),
    ),
    GoRoute(
      path: '/investor/dashboard',
      builder: (context, state) => const InvestorDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/login',
      builder: (context, state) => const StaffLoginScreen(),
    ),
    GoRoute(
      path: '/admin/dashboard',
      builder: (context, state) => const StaffDashboardScreen(),
      redirect: (context, state) {
        final token = LocalStorage.getAdminToken();
        if (token == null) return '/admin/login';
        return null;
      },
    ),
    GoRoute(
      path: '/admin/approvals',
      builder: (context, state) => const StaffApprovalsScreen(),
      redirect: (context, state) {
        final token = LocalStorage.getAdminToken();
        if (token == null) return '/admin/login';
        return null;
      },
    ),
    GoRoute(
      path: '/admin/directory',
      builder: (context, state) => const StaffDirectoryScreen(),
      redirect: (context, state) {
        final token = LocalStorage.getAdminToken();
        if (token == null) return '/admin/login';
        return null;
      },
    ),
    GoRoute(
      path: '/admin/scanner',
      builder: (context, state) => const EventScannerScreen(),
      redirect: (context, state) {
        final token = LocalStorage.getAdminToken();
        if (token == null) return '/admin/login';
        return null;
      },
    ),
    GoRoute(
      path: '/admin/live-dashboard/:id',
      builder: (context, state) => LiveEventDashboardScreen(eventId: state.pathParameters['id']!),
      redirect: (context, state) {
        final token = LocalStorage.getAdminToken();
        if (token == null) return '/admin/login';
        return null;
      },
    ),
    GoRoute(
      path: '/events',
      builder: (context, state) => const EventsListScreen(),
    ),
    // Static segments (/events/check, /events/status/:token) are declared
    // before the dynamic /events/:slug catch-all so go_router prefers them.
    GoRoute(
      path: '/events/check',
      builder: (context, state) => const EventCheckStatusScreen(),
    ),
    GoRoute(
      path: '/events/status/:token',
      builder: (context, state) =>
          EventStatusScreen(token: state.pathParameters['token']!),
    ),
    GoRoute(
      path: '/events/:slug/register',
      builder: (context, state) =>
          EventRegistrationScreen(slug: state.pathParameters['slug']!),
    ),
    GoRoute(
      path: '/events/:slug',
      builder: (context, state) =>
          EventDetailScreen(slug: state.pathParameters['slug']!),
    ),
  ],
);
