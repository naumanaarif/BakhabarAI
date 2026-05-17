import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/auth_provider.dart';
import 'auth/signup_screen.dart';
import '../models/incident.dart';
import '../services/api_service.dart';
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
  bool _isLoading = true;
  String? _error;
  List<Incident> _incidents = [];
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
    _loadData();
    Geolocator.checkPermission().then((permission) {
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        if (mounted) setState(() => _hasLocationPermission = true);
      }
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _showLocationPopup();
      }
    });
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
                    final granted = await _locationService.handleLocationPermission();
                    if (granted) {
                      setState(() {
                        _hasLocationPermission = true;
                      });
                      final pos = await _locationService.getCurrentPosition();
                      if (pos != null && _mapController != null) {
                        _mapController!.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng(pos.latitude, pos.longitude),
                            14.0,
                          ),
                        );
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Location access granted! Live tracking enabled.'),
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
        );
      },
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final incidents = await _apiService.getIncidents();
      if (mounted) {
        setState(() {
          _incidents = incidents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
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
                              icon: const Icon(Icons.close, color: AppColors.textPrimary),
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
                            onAuthenticated: () {
                              ref.read(authProvider.notifier).login('Ahmed');
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Successfully authenticated!'),
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
                          child: const Text('Log Out', style: TextStyle(color: AppColors.dangerRed)),
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
                    color: authState.isAuthenticated ? AppColors.accent : Colors.grey.shade300,
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
            Text(
              authState.isAuthenticated ? 'Salam, ${authState.userName}!' : 'Salam!',
              style: AppTextStyles.h1.copyWith(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 20,
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
                  icon: const Icon(LucideIcons.bell, color: AppColors.textPrimary, size: 24),
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
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.accent,
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
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        GoogleMap(
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
                        // Overlay glass panel
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.mapPin, color: AppColors.accent, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Monitoring Zone Alpha',
                                      style: AppTextStyles.label.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
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
                                      '${_incidents.length} Active',
                                      style: AppTextStyles.bodyMuted.copyWith(
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
                _buildPreviewList(),
                const SizedBox(height: 120), // Space for FAB and bottom navigation
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewList() {
    if (_isLoading) {
      return Column(
        children: List.generate(2, (index) => const IncidentCardSkeleton()),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              const Icon(LucideIcons.alertTriangle, color: AppColors.dangerRed, size: 40),
              const SizedBox(height: 8),
              Text('Error loading preview', style: AppTextStyles.h2),
              const SizedBox(height: 4),
              Text(_error!, style: AppTextStyles.bodyMuted, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (_incidents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(LucideIcons.checkCircle, color: AppColors.successGreen, size: 40),
            const SizedBox(height: 12),
            Text('All Clear', style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text('No active crises in your area.', style: AppTextStyles.bodyMuted),
          ],
        ),
      );
    }

    // Show up to 3 incidents as a preview
    final previewList = _incidents.take(3).toList();

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
                  builder: (context) => IncidentDetailScreen(incidentId: incident.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(
                    color: severityColor,
                    width: 4,
                  ),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      const Icon(LucideIcons.clock, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '12 mins ago • ${incident.location.name}',
                        style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Colors.black12),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AI Confidence Rating',
                        style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
                      ),
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

    final List<Map<String, dynamic>> notifications = [
      {
        'title': 'Urban Flood Detected (G-10)',
        'message': 'SignalCollector normalized WhatsApp report: heavy rain & water logging in G-10. Credibility: 0.95.',
        'time': '5 mins ago',
        'type': 'incident',
        'icon': LucideIcons.waves,
        'color': AppColors.severityHigh,
      },
      {
        'title': 'Resource Allocation Dispatch',
        'message': 'PlannerAgent automatically dispatched 3 Ambulances and 2 Rescue Squads to G-10 Flood area.',
        'time': '8 mins ago',
        'type': 'resource',
        'icon': LucideIcons.hardHat,
        'color': AppColors.severityMedium,
      },
      {
        'title': 'Simulation Model Completed',
        'message': 'ExecutorAgent executed simulation. High traffic reroutes triggered via Kashmir Highway.',
        'time': '12 mins ago',
        'type': 'sim',
        'icon': LucideIcons.cpu,
        'color': AppColors.accent,
      },
      {
        'title': 'False Alarm Clearance (I-8)',
        'message': 'ReporterAgent issued alert cancellation: Utility sensor checks confirm standard dry conditions in I-8.',
        'time': '1 hour ago',
        'type': 'incident',
        'icon': LucideIcons.checkCircle,
        'color': AppColors.severityLow,
      },
    ];

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
                  Text(
                    'Notifications',
                    style: AppTextStyles.h1.copyWith(fontSize: 22),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Colors.black12),
            
            // Notification List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final noti = notifications[index];
                  return Container(
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
                        left: BorderSide(
                          color: noti['color'] as Color,
                          width: 4,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (noti['color'] as Color).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            noti['icon'] as IconData,
                            color: noti['color'] as Color,
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
                                      noti['title'] as String,
                                      style: AppTextStyles.label.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    noti['time'] as String,
                                    style: AppTextStyles.bodyMuted.copyWith(fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                noti['message'] as String,
                                style: AppTextStyles.bodyMuted.copyWith(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
