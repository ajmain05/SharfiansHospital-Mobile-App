import 'package:go_router/go_router.dart';

import '../../features/events/screens/event_check_status_screen.dart';
import '../../features/events/screens/event_registration_screen.dart';
import '../../features/events/screens/event_status_screen.dart';
import '../../features/events/screens/events_list_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/investor_auth/screens/investor_login_screen.dart';
import '../../features/investor_dashboard/screens/investor_dashboard_screen.dart';
import '../../features/investor_registration/screens/investor_registration_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/register', builder: (context, state) => const InvestorRegistrationScreen()),
    GoRoute(path: '/investor/login', builder: (context, state) => const InvestorLoginScreen()),
    GoRoute(path: '/investor/dashboard', builder: (context, state) => const InvestorDashboardScreen()),
    GoRoute(path: '/events', builder: (context, state) => const EventsListScreen()),
    // Static segments (/events/check, /events/status/:token) are declared
    // before the dynamic /events/:slug catch-all so go_router prefers them.
    GoRoute(path: '/events/check', builder: (context, state) => const EventCheckStatusScreen()),
    GoRoute(
      path: '/events/status/:token',
      builder: (context, state) => EventStatusScreen(token: state.pathParameters['token']!),
    ),
    GoRoute(
      path: '/events/:slug',
      builder: (context, state) => EventRegistrationScreen(slug: state.pathParameters['slug']!),
    ),
  ],
);
