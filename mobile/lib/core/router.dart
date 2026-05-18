import 'package:flutter/material.dart';
import '../main.dart';
import '../screens/splash_screen.dart';
import '../screens/map_screen.dart';
import '../screens/incidents_screen.dart';
import '../screens/report_screen.dart';
import '../screens/agent_logs_screen.dart';
import '../screens/incident_detail_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String home = '/home';
  static const String map = '/map';
  static const String incidents = '/incidents';
  static const String aiAssist = '/aiAssist';
  static const String logs = '/logs';
  static const String incidentDetail = '/incidentDetail';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _pageRoute(const SplashScreen(), settings);
      case home:
        return _pageRoute(const MainShell(), settings);
      case map:
        return _pageRoute(const MapScreen(), settings);
      case incidents:
        return _pageRoute(const IncidentsScreen(), settings);
      case aiAssist:
        return _pageRoute(const ReportScreen(), settings);
      case logs:
        return _pageRoute(const AgentLogsScreen(), settings);
      case incidentDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final incidentId = args?['incidentId'] as String? ?? '1';
        return _pageRoute(IncidentDetailScreen(incidentId: incidentId), settings);
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }

  // Smooth transition builder
  static PageRouteBuilder _pageRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.05);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }
}
