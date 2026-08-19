// ignore: unused_import
import 'package:flutter/material.dart' show BuildContext, Animation, Widget;
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
import '../../features/splash/screens/splash_screen.dart';
import '../storage/local_storage.dart';
import '../widgets/tap_scale.dart';
import '../widgets/main_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // ── Splash ──────────────────────────────────────────────────────────────
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SplashScreen(),
        transitionsBuilder: fadeTransition,
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),

    // ── Main Shell (Bottom Nav) ─────────────────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => MainScaffold(navigationShell: navigationShell),
      branches: [
        // Tab 1: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const HomeScreen(),
                transitionsBuilder: fadeTransition,
                transitionDuration: const Duration(milliseconds: 350),
              ),
              routes: [
                GoRoute(
                  path: 'gallery',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const GalleryScreen(),
                    transitionsBuilder: slideUpTransition,
                    transitionDuration: const Duration(milliseconds: 320),
                  ),
                ),
                GoRoute(
                  path: 'faq',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const FaqScreen(),
                    transitionsBuilder: slideUpTransition,
                    transitionDuration: const Duration(milliseconds: 320),
                  ),
                ),
                GoRoute(
                  path: 'bank-details',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const BankDetailsScreen(),
                    transitionsBuilder: slideUpTransition,
                    transitionDuration: const Duration(milliseconds: 320),
                  ),
                ),
                GoRoute(
                  path: 'career',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const CareerScreen(),
                    transitionsBuilder: slideUpTransition,
                    transitionDuration: const Duration(milliseconds: 320),
                  ),
                ),
              ],
            ),
          ],
        ),
        // Tab 2: Events
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/events',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const EventsListScreen(),
                transitionsBuilder: fadeTransition,
                transitionDuration: const Duration(milliseconds: 350),
              ),
              routes: [
                GoRoute(
                  path: 'check',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const EventCheckStatusScreen(),
                    transitionsBuilder: slideUpTransition,
                    transitionDuration: const Duration(milliseconds: 320),
                  ),
                ),
                GoRoute(
                  path: 'status/:token',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: EventStatusScreen(token: state.pathParameters['token']!),
                    transitionsBuilder: slideUpTransition,
                    transitionDuration: const Duration(milliseconds: 320),
                  ),
                ),
                GoRoute(
                  path: ':slug/register',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: EventRegistrationScreen(slug: state.pathParameters['slug']!),
                    transitionsBuilder: scaleUpTransition,
                    transitionDuration: const Duration(milliseconds: 350),
                  ),
                ),
                GoRoute(
                  path: ':slug',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: EventDetailScreen(slug: state.pathParameters['slug']!),
                    transitionsBuilder: slideUpTransition,
                    transitionDuration: const Duration(milliseconds: 320),
                  ),
                ),
              ],
            ),
          ],
        ),
        // Tab 3: Portal
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/investor/dashboard',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const InvestorDashboardScreen(),
                transitionsBuilder: fadeTransition,
                transitionDuration: const Duration(milliseconds: 400),
              ),
            ),
          ],
        ),
      ],
    ),

    // ── Public ──────────────────────────────────────────────────────────────


    // ── Investor (Non-tab routes) ────────────────────────────────────────────
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const InvestorRegistrationScreen(),
        transitionsBuilder: scaleUpTransition,
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ),
    GoRoute(
      path: '/investor/login',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const InvestorLoginScreen(),
        transitionsBuilder: scaleUpTransition,
        transitionDuration: const Duration(milliseconds: 350),
      ),
      redirect: (context, state) {
        final phone = LocalStorage.getInvestorPhone();
        if (phone != null && phone.isNotEmpty) return '/investor/dashboard';
        return null;
      },
    ),

    // ── Admin ────────────────────────────────────────────────────────────────
    GoRoute(
      path: '/admin/login',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const StaffLoginScreen(),
        transitionsBuilder: scaleUpTransition,
        transitionDuration: const Duration(milliseconds: 350),
      ),
      redirect: (context, state) {
        final token = LocalStorage.getAdminToken();
        if (token != null) return '/admin/dashboard';
        return null;
      },
    ),
    GoRoute(
      path: '/admin/dashboard',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const StaffDashboardScreen(),
        transitionsBuilder: fadeTransition,
        transitionDuration: const Duration(milliseconds: 350),
      ),
      redirect: (context, state) {
        final token = LocalStorage.getAdminToken();
        if (token == null) return '/admin/login';
        return null;
      },
    ),
    GoRoute(
      path: '/admin/approvals',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const StaffApprovalsScreen(),
        transitionsBuilder: slideUpTransition,
        transitionDuration: const Duration(milliseconds: 320),
      ),
      redirect: (context, state) {
        final token = LocalStorage.getAdminToken();
        if (token == null) return '/admin/login';
        return null;
      },
    ),
    GoRoute(
      path: '/admin/directory',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const StaffDirectoryScreen(),
        transitionsBuilder: slideUpTransition,
        transitionDuration: const Duration(milliseconds: 320),
      ),
      redirect: (context, state) {
        final token = LocalStorage.getAdminToken();
        if (token == null) return '/admin/login';
        return null;
      },
    ),
    GoRoute(
      path: '/admin/scanner',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const EventScannerScreen(),
        transitionsBuilder: scaleUpTransition,
        transitionDuration: const Duration(milliseconds: 350),
      ),
      redirect: (context, state) {
        final token = LocalStorage.getAdminToken();
        if (token == null) return '/admin/login';
        return null;
      },
    ),
    GoRoute(
      path: '/admin/live-dashboard/:id',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: LiveEventDashboardScreen(eventId: state.pathParameters['id']!),
        transitionsBuilder: scaleUpTransition,
        transitionDuration: const Duration(milliseconds: 350),
      ),
      redirect: (context, state) {
        final token = LocalStorage.getAdminToken();
        if (token == null) return '/admin/login';
        return null;
      },
    ),
  ],
);
