import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/auth_provider.dart';
import '../core/utils.dart';
import 'auth/signup_screen.dart';
import '../models/incident.dart';
import '../models/agent_log.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';
import '../widgets/skeleton_loader.dart';
import 'incident_detail_screen.dart';
import 'incidents_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  late Stream<List<Incident>> _incidentsStream;
  late Stream<List<Incident>> _historyStream;
  late Stream<List<AgentTrace>> _logsStream;
  StreamSubscription? _incidentSubscription;
  String? _lastIncidentId;
  String _currentCity = 'Detecting...';

  bool _hasLocationPermission = false;
  bool _hasUnreadNotifications = true;
  GoogleMapController? _mapController;

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(33.6844, 73.0479),
    zoom: 11.5,
  );

  @override
  void initState() {
    super.initState();
    _incidentsStream = _apiService.getIncidentsStream();
    _historyStream = _apiService.getIncidentHistoryStream();
    _logsStream = _apiService.getAgentLogsStream();
    _detectLocation();

    // Listen for new incident alerts
    _incidentSubscription = _incidentsStream.listen((incidents) {
      if (incidents.isNotEmpty && mounted) {
        // Sort by id or timestamp if available, but for now we assume the list update is significant
        // We'll take the first one as the most recent/relevant
        final latestIncident = incidents.first;

        if (_lastIncidentId != latestIncident.id) {
          final isNew = _lastIncidentId != null;
          _lastIncidentId = latestIncident.id;

          if (isNew) {
            setState(() {
              _hasUnreadNotifications = true;
            });

            // Clear existing snackbars to prevent stacking/manual removal
            ScaffoldMessenger.of(context).clearSnackBars();

            // Show optimized in-app notification
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4), // Auto-removes
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 70), // Positions above nav bar
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.black.withOpacity(0.9),
                content: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => IncidentDetailScreen(incidentId: latestIncident.id),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.alertTriangle,
                        color: _getSeverityColor(latestIncident.severity),
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NEW CRISIS DETECTED',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              '${latestIncident.type.toUpperCase()} in ${latestIncident.location.name.split(',')[0]}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, color: Colors.white54, size: 16),
                    ],
                  ),
                ),
              ),
            );

            // Show outside-app notification
            NotificationService().showNotification(
              id: latestIncident.id.hashCode,
              title: 'CRISIS ALERT: ${latestIncident.type.toUpperCase()}',
              body:
                  'Detected in ${latestIncident.location.name}. Confidence: ${(latestIncident.confidence * 100).toInt()}%',
            );
          }
        }
      }
    });

    Geolocator.checkPermission().then((permission) {
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        if (mounted) setState(() => _hasLocationPermission = true);
      }
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _showLocationPopup();
      }
    });
  }

  @override
  void dispose() {
    _incidentSubscription?.cancel();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      if (mounted) setState(() => _hasLocationPermission = true);
      final pos = await _locationService.getCurrentPosition();
      if (pos != null) {
        try {
          // Detect city based on Latitude (Karachi ~24.8, Islamabad ~33.6)
          if (pos.latitude < 26) {
            if (mounted) setState(() => _currentCity = 'Karachi');
          } else {
            if (mounted) setState(() => _currentCity = 'Islamabad');
          }

          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(pos.latitude, pos.longitude),
                12.0,
              ),
            );
          }
        } catch (e) {
          if (mounted) setState(() => _currentCity = 'Pakistan');
        }
      } else {
        if (mounted) setState(() => _currentCity = 'Islamabad');
      }
    } else {
      if (mounted) setState(() => _currentCity = 'Islamabad');
    }
  }

  void _showLocationPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 64,
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Enable Location',
                    style: AppTextStyles.h1.copyWith(fontSize: 22),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'BakhabarAI needs your location to detect crises in your area and send timely alerts.',
                    style: AppTextStyles.bodyMuted,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      final granted = await _locationService
                          .handleLocationPermission();
                      if (granted) {
                        setState(() {
                          _hasLocationPermission = true;
                        });
                        await _detectLocation();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Location access granted! Live tracking enabled.',
                            ),
                            backgroundColor: AppColors.successGreen,
                          ),
                        );
                      }
                    },
                    child: const Text('Allow Access'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: Text(
                      'Not Now',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'HIGH':
      case 'CRITICAL':
        return AppColors.severityHigh;
      case 'MEDIUM':
      case 'ELEVATED':
        return AppColors.severityMedium;
      case 'LOW':
      case 'ROUTINE':
      default:
        return AppColors.severityLow;
    }
  }

  Color _getSeverityBgColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'HIGH':
      case 'CRITICAL':
        return AppColors.severityHigh.withOpacity(0.12);
      case 'MEDIUM':
      case 'ELEVATED':
        return AppColors.severityMedium.withOpacity(0.12);
      case 'LOW':
      case 'ROUTINE':
      default:
        return AppColors.severityLow.withOpacity(0.12);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (!authState.isAuthenticated) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => Container(
                      height: MediaQuery.of(context).size.height * 0.85,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                        child: Scaffold(
                          backgroundColor: AppColors.primary,
                          appBar: AppBar(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            centerTitle: true,
                            leading: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: AppColors.textPrimary,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            title: const Text(
                              'Sign Up / Log In',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          body: SignupScreen(
                            onAuthenticated: (name) {
                              ref.read(authProvider.notifier).login(name);
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Successfully authenticated as $name!',
                                  ),
                                  backgroundColor: AppColors.successGreen,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Log Out'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(authProvider.notifier).logout();
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Log Out',
                            style: TextStyle(color: AppColors.dangerRed),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: authState.isAuthenticated
                        ? AppColors.accent
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuCxUKmia2wx8eVAvXT0lkvLLWAjIb20DQWVZINsTAYmYbObi-tD1dc0cTtLwf2elMnGAuQuc-ZMMX66aSTrhoYwO8diUfnlDxC-hc2-F3HQiSB8EPCsNTSpkUhBqlW4lxb9ylebE-5S9Ofs_DajW-sIjJVYD3XpfwxhQBq5U5hYwq5UOvJd0VYsFKvm382WYUfH3p9PkZUucNsnxf-3wzNtYPpQNQTX4EdDRavqEYy4YxPuW2p6mUTXEyGh7_ZZ9EG_sZNQ0Ue72SA',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                authState.isAuthenticated
                    ? 'Salam, ${authState.userName}!'
                    : 'Salam!',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: AppTextStyles.h1.copyWith(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    LucideIcons.bell,
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                  onPressed: () => _showNotificationsSheet(context),
                ),
                if (_hasUnreadNotifications)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Incident>>(
        stream: _incidentsStream,
        builder: (context, snapshot) {
          final incidents = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _incidentsStream = _apiService.getIncidentsStream();
              });
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Live Mini-Map Preview Card
                    Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            RepaintBoundary(
                              child: GoogleMap(
                                initialCameraPosition: _initialCameraPosition,
                                zoomControlsEnabled: false,
                                myLocationEnabled: _hasLocationPermission,
                                myLocationButtonEnabled: false,
                                zoomGesturesEnabled: false,
                                scrollGesturesEnabled: false,
                                tiltGesturesEnabled: false,
                                rotateGesturesEnabled: false,
                                onMapCreated: (controller) {
                                  _mapController = controller;
                                },
                              ),
                            ),
                            // Overlay glass panel
                            Positioned(
                              bottom: 12,
                              left: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(
                                            LucideIcons.mapPin,
                                            color: AppColors.accent,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              incidents.isNotEmpty 
                                                  ? incidents.first.location.name.split(',')[0] 
                                                  : '$_currentCity Monitoring',
                                              style: AppTextStyles.label.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppColors.dangerRed,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${incidents.length} Active',
                                          style: AppTextStyles.bodyMuted
                                              .copyWith(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Active Incidents list preview header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Active Incidents',
                          style: AppTextStyles.h1.copyWith(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 22,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to full list screen
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const IncidentsScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'View All',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Incident list preview
                    _buildPreviewList(snapshot),
                    const SizedBox(
                      height: 120,
                    ), // Space for FAB and bottom navigation
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreviewList(AsyncSnapshot<List<Incident>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Column(
        children: List.generate(2, (index) => const IncidentCardSkeleton()),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              const Icon(
                LucideIcons.alertTriangle,
                color: AppColors.dangerRed,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text('Error loading preview', style: AppTextStyles.h2),
              const SizedBox(height: 4),
              Text(
                snapshot.error.toString(),
                style: AppTextStyles.bodyMuted,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final incidents = snapshot.data ?? [];

    if (incidents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(
              LucideIcons.checkCircle,
              color: AppColors.successGreen,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text('All Clear', style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text(
              'No active crises in your area.',
              style: AppTextStyles.bodyMuted,
            ),
          ],
        ),
      );
    }

    // Show up to 3 incidents as a preview
    final previewList = incidents.take(3).toList();

    return Column(
      children: previewList.map((incident) {
        final severityColor = _getSeverityColor(incident.severity);
        final confidencePercent = (incident.confidence * 100).toInt();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      IncidentDetailScreen(incidentId: incident.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(color: severityColor, width: 4),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${incident.location.name.split(',')[0]} ${incident.type.toUpperCase()}',
                          style: AppTextStyles.h2.copyWith(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getSeverityBgColor(incident.severity),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          incident.severity,
                          style: AppTextStyles.label.copyWith(
                            color: severityColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.clock,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${TimeUtils.formatTimeAgo(incident.timestamp)} • ${incident.location.name}',
                          style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Colors.black12),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'AI Confidence Rating',
                          style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$confidencePercent%',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    setState(() {
      _hasUnreadNotifications = false;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alert History',
                        style: AppTextStyles.h1.copyWith(fontSize: 22),
                      ),
                      const Text(
                        'Recent emergency notifications',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          // For demo, we just hide the red dot. 
                          // In a real app, this would update a 'last_read' timestamp in Firebase.
                          setState(() {
                            _hasUnreadNotifications = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notifications marked as read'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: AppColors.textPrimary, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Colors.black12),

            // Notification List (Live from Incidents)
            Expanded(
              child: StreamBuilder<List<Incident>>(
                stream: _historyStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.accent),
                          SizedBox(height: 16),
                          Text('Updating history...',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading alerts',
                        style: AppTextStyles.bodyMuted,
                      ),
                    );
                  }

                  final incidents = snapshot.data ?? [];
                  if (incidents.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.bellOff,
                            size: 48,
                            color: AppColors.textMuted.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text('No new alerts', style: AppTextStyles.bodyMuted),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    itemCount: incidents.length,
                    itemBuilder: (context, index) {
                      final incident = incidents[index];
                      final color = _getSeverityColor(incident.severity);

                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop(); // Close sheet
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  IncidentDetailScreen(incidentId: incident.id),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border(
                              left: BorderSide(color: color, width: 4),
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.alertTriangle,
                                  color: color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            incident.type.toUpperCase(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          TimeUtils.formatTimeAgo(incident.timestamp),
                                          style: AppTextStyles.labelMuted
                                              .copyWith(fontSize: 10),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'A ${incident.severity.toLowerCase()} severity crisis detected in ${incident.location.name}. Confidence is ${(incident.confidence * 100).toInt()}%.',
                                      style: AppTextStyles.bodyMuted.copyWith(
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'View Details',
                                      style: TextStyle(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}
