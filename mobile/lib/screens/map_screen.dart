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
  bool _isLoading = true;
  String? _error;
  List<Incident> _incidents = [];
  List<Incident> _filteredIncidents = [];
  bool _hasLocationPermission = false;
  
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  
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

  @override
  void initState() {
    super.initState();
    _loadData();
    Geolocator.checkPermission().then((permission) {
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        if (mounted) setState(() => _hasLocationPermission = true);
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final incidents = await _apiService.getIncidents();
      if (mounted) {
        setState(() {
          _incidents = incidents;
          _filteredIncidents = incidents;
          _buildMarkers();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading map data: $_error'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    }
  }

  void _filterIncidents(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'All') {
        _filteredIncidents = _incidents;
      } else {
        _filteredIncidents = _incidents
            .where((i) => i.type.toLowerCase() == filter.toLowerCase())
            .toList();
      }
      _buildMarkers();
    });
  }

  void _searchArea(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredIncidents = _incidents;
        _buildMarkers();
      });
      return;
    }
    setState(() {
      _filteredIncidents = _incidents
          .where((i) =>
              i.location.name.toLowerCase().contains(query.toLowerCase()) ||
              i.type.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _buildMarkers();
    });
  }

  void _buildMarkers() {
    _markers.clear();
    for (var incident in _filteredIncidents) {
      double hue;
      switch (incident.severity.toUpperCase()) {
        case 'HIGH':
        case 'CRITICAL':
          hue = BitmapDescriptor.hueRed;
          break;
        case 'MEDIUM':
        case 'ELEVATED':
          hue = BitmapDescriptor.hueOrange;
          break;
        case 'LOW':
        case 'ROUTINE':
        default:
          hue = BitmapDescriptor.hueGreen;
          break;
      }

      _markers.add(
        Marker(
          markerId: MarkerId(incident.id),
          position: LatLng(incident.location.lat, incident.location.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: '${incident.type.toUpperCase()} - ${incident.severity}',
            snippet: incident.location.name,
          ),
          onTap: () {
            setState(() {
              _selectedIncidentForPanel = incident;
              _showPanel = true;
            });
          },
        ),
      );
    }
  }

  void _zoomToUserLocation() async {
    setState(() => _isLoading = true);
    final pos = await _locationService.getCurrentPosition();
    setState(() {
      _isLoading = false;
      if (pos != null) _hasLocationPermission = true;
    });

    if (pos != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(pos.latitude, pos.longitude),
          15.0,
        ),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Centered on live GPS location.'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not fetch GPS location. Make sure permissions are allowed.'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            markers: _markers,
            myLocationEnabled: _hasLocationPermission,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onTap: (_) {
              setState(() {
                _showPanel = false;
              });
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
                    onChanged: _searchArea,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: 'Search areas, sectors...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(LucideIcons.search, color: AppColors.textMuted, size: 20),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              _searchArea('');
                            },
                          )
                        : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
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
                      _buildFilterChip('Flood', LucideIcons.waves),
                      _buildFilterChip('Heatwave', LucideIcons.thermometerSun),
                      _buildFilterChip('Accident', LucideIcons.car),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating GPS Locate Button
          Positioned(
            bottom: _showPanel ? 260 : 100, // moves up if bottom sheet is showing!
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
              bottom: 100, // above bottom navigation tab
              left: 16,
              right: 16,
              child: _buildGlassBottomPanel(_selectedIncidentForPanel!),
            ),
          
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.15),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => _filterIncidents(label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
            )
          ],
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
              Row(
                children: [
                  Icon(
                    incident.type.toLowerCase() == 'flood' ? LucideIcons.waves : LucideIcons.alertTriangle,
                    color: severityColor,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${incident.location.name.split(',')[0]} ${incident.type.toUpperCase()}',
                    style: AppTextStyles.h2.copyWith(fontSize: 18),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                onPressed: () => setState(() => _showPanel = false),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Kashmir Highway underpass submerged. Alternative Route: redirected via Sector G-9.',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Emergency services are currently managing perimeter security. Estimated travel delay in area: +12 mins.',
            style: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
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
