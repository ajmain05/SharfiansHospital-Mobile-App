import 'package:go_router/go_router.dart';

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
  ],
);
