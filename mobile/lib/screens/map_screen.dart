import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import '../core/theme.dart';
import '../models/incident.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'incident_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  late Stream<List<Incident>> _incidentsStream;
  
  bool _hasLocationPermission = false;
  GoogleMapController? _mapController;
  
  String _selectedFilter = 'All'; // 'All', 'Flood', 'Heatwave', 'Accident'
  final TextEditingController _searchController = TextEditingController();

  // Glassmorphic bottom panel state
  bool _showPanel = false;
  Incident? _selectedIncidentForPanel;

  // Default to Islamabad coordinates
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(33.6844, 73.0479),
    zoom: 12.5,
  );

  bool _isCentering = false;
  bool _hasInitialZoom = false;

  @override
  void initState() {
    super.initState();
    _incidentsStream = _apiService.getIncidentsStream();
    _checkLocationPermission();
  }

  IconData _getIconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('flood')) return LucideIcons.waves;
    if (t.contains('heat')) return LucideIcons.thermometerSun;
    if (t.contains('accident')) return LucideIcons.car;
    if (t.contains('fire')) return LucideIcons.flame;
    if (t.contains('power')) return LucideIcons.zap;
    return LucideIcons.alertTriangle;
  }

  Future<void> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      if (mounted && !_hasLocationPermission) {
        setState(() => _hasLocationPermission = true);
        // If map is already created, zoom now
        if (_mapController != null && !_hasInitialZoom) {
          _zoomToUserLocation(showSnackBar: false);
          _hasInitialZoom = true;
        }
      }
    }
  }

  void _zoomToUserLocation({bool showSnackBar = true}) async {
    if (_isCentering) return;
    _isCentering = true;

    try {
      final pos = await _locationService.getCurrentPosition();
      if (pos != null && _mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(pos.latitude, pos.longitude),
            15.0,
          ),
        );
        
        if (mounted && showSnackBar) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Centered on live GPS location.'),
              backgroundColor: AppColors.successGreen,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted && showSnackBar) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not fetch GPS location. Make sure permissions are allowed.'),
              backgroundColor: AppColors.dangerRed,
            ),
          );
        }
      }
    } finally {
      _isCentering = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Periodically check permission if we haven't zoomed yet 
    if (!_hasInitialZoom) {
      _checkLocationPermission();
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: StreamBuilder<List<Incident>>(
        stream: _incidentsStream,
        builder: (context, snapshot) {
          final incidents = snapshot.data ?? [];
          final filtered = _selectedFilter == 'All' 
              ? incidents 
              : incidents.where((i) => i.type.toLowerCase().contains(_selectedFilter.toLowerCase())).toList();

          final Set<Marker> markers = {};
          final Set<Circle> circles = {};

          for (var incident in filtered) {
            Color color;
            double hue;
            double radius;

            switch (incident.severity.toUpperCase()) {
              case 'HIGH':
              case 'CRITICAL':
                color = AppColors.severityHigh;
                hue = BitmapDescriptor.hueRed;
                radius = 500;
                break;
              case 'MEDIUM':
              case 'ELEVATED':
                color = AppColors.severityMedium;
                hue = BitmapDescriptor.hueOrange;
                radius = 300;
                break;
              case 'LOW':
              case 'ROUTINE':
              default:
                color = AppColors.severityLow;
                hue = BitmapDescriptor.hueGreen;
                radius = 200;
                break;
            }

            final position = LatLng(incident.location.lat, incident.location.lng);

            markers.add(
              Marker(
                markerId: MarkerId(incident.id),
                position: position,
                icon: BitmapDescriptor.defaultMarkerWithHue(hue),
                onTap: () {
                  setState(() {
                    _selectedIncidentForPanel = incident;
                    _showPanel = true;
                  });
                  // Use microtask to avoid frame lag during state change
                  Future.microtask(() {
                    _mapController?.animateCamera(CameraUpdate.newLatLng(position));
                  });
                },
              ),
            );

            circles.add(
              Circle(
                circleId: CircleId('${incident.id}_zone'),
                center: position,
                radius: radius,
                fillColor: color.withOpacity(0.15),
                strokeColor: color.withOpacity(0.5),
                strokeWidth: 2,
                consumeTapEvents: true, // Prevent map 'onTap' from hiding panel immediately
                onTap: () {
                  setState(() {
                    _selectedIncidentForPanel = incident;
                    _showPanel = true;
                  });
                },
              ),
            );
          }

          return Stack(
            children: [
              // Google Map
              GoogleMap(
                initialCameraPosition: _initialCameraPosition,
                markers: markers,
                circles: circles,
                myLocationEnabled: _hasLocationPermission,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (_hasLocationPermission && !_hasInitialZoom) {
                    _zoomToUserLocation(showSnackBar: false);
                    _hasInitialZoom = true;
                  }
                },
                onTap: (_) {
                  if (_showPanel) {
                    setState(() {
                      _showPanel = false;
                    });
                  }
                },
              ),
              
              // Floating Search Bar & Filters at Top
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    // Search Input Field
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: AppTextStyles.body,
                        onChanged: (val) => setState(() {}), // Trigger rebuild for search
                        decoration: InputDecoration(
                          hintText: 'Search areas, sectors...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(LucideIcons.search, color: AppColors.textMuted, size: 20),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Horizontal Filters
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', LucideIcons.layers),
                          ...(snapshot.data ?? []).map((i) => i.type).toSet().map((type) => 
                            _buildFilterChip(
                              type[0].toUpperCase() + type.substring(1).toLowerCase(), 
                              _getIconForType(type)
                            )
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Floating GPS Locate Button
              Positioned(
                bottom: _showPanel ? 260 : 100,
                right: 16,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.locate, color: AppColors.accent, size: 24),
                    onPressed: _zoomToUserLocation,
                  ),
                ),
              ),

              // Bottom Glassmorphic Panel
              if (_showPanel && _selectedIncidentForPanel != null)
                Positioned(
                  bottom: 100,
                  left: 16,
                  right: 16,
                  child: _buildGlassBottomPanel(_selectedIncidentForPanel!),
                ),
              
              if (snapshot.connectionState == ConnectionState.waiting)
                Container(
                  color: Colors.black.withOpacity(0.15),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassBottomPanel(Incident incident) {
    final isHigh = incident.severity.toUpperCase() == 'HIGH' || incident.severity.toUpperCase() == 'CRITICAL';
    final severityColor = isHigh ? AppColors.severityHigh : AppColors.severityMedium;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      incident.type.toLowerCase().contains('flood') ? LucideIcons.waves : LucideIcons.alertTriangle,
                      color: severityColor,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${incident.location.name.split(',')[0]} ${incident.type.toUpperCase()}',
                        style: AppTextStyles.h2.copyWith(fontSize: 18),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                onPressed: () => setState(() => _showPanel = false),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            incident.status.toUpperCase() == 'ACTIVE' 
              ? 'Critical ${incident.type} detected. AI-driven response and simulation active.'
              : 'Incident status: ${incident.status}. Monitoring continues.',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => IncidentDetailScreen(incidentId: incident.id),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('View Full Details'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
