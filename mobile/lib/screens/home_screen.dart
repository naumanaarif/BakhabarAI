import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import '../core/theme.dart';
import '../core/router.dart';
import '../models/incident.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../widgets/skeleton_loader.dart';
import 'incident_detail_screen.dart';
import 'incidents_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  bool _isLoading = true;
  String? _error;
  List<Incident> _incidents = [];
  bool _hasLocationPermission = false;
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
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 1),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCxUKmia2wx8eVAvXT0lkvLLWAjIb20DQWVZINsTAYmYbObi-tD1dc0cTtLwf2elMnGAuQuc-ZMMX66aSTrhoYwO8diUfnlDxC-hc2-F3HQiSB8EPCsNTSpkUhBqlW4lxb9ylebE-5S9Ofs_DajW-sIjJVYD3XpfwxhQBq5U5hYwq5UOvJd0VYsFKvm382WYUfH3p9PkZUucNsnxf-3wzNtYPpQNQTX4EdDRavqEYy4YxPuW2p6mUTXEyGh7_ZZ9EG_sZNQ0Ue72SA',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Salam, Ahmed!',
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
                  onPressed: () {},
                ),
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
}
