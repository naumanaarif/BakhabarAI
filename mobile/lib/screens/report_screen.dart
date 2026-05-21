import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/theme.dart';
import '../core/auth_provider.dart';
import '../services/api_service.dart';
import 'auth/signup_screen.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  Timer? _debounce;

  // Form Fields
  String _selectedType = 'Flood';
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedLocation = '';
  
  // Media Fields
  XFile? _selectedMedia;
  final ImagePicker _picker = ImagePicker();

  final List<String> _crisisTypes = [
    'Flood',
    'Heatwave',
    'Accident',
    'Power Outage',
    'Protest',
    'Disease'
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final XFile? media = await _picker.pickImage(source: ImageSource.gallery);
    // You could also add pickVideo
    if (media != null) {
      setState(() {
        _selectedMedia = media;
      });
    }
  }

  Future<String?> _uploadMedia(XFile media) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${media.name}';
      final ref = FirebaseStorage.instance.ref().child('incident_media').child(fileName);
      final uploadTask = await ref.putFile(File(media.path));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Media upload failed: $e");
      return null;
    }
  }

  void _submitIncident() async {
    final description = _descriptionController.text.trim();
    final locationName = _selectedLocation.trim();

    if (description.isEmpty || locationName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all the required fields.'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? mediaUrl;
      if (_selectedMedia != null) {
        mediaUrl = await _uploadMedia(_selectedMedia!);
      }

      // Submit to backend
      await _apiService.submitReport(
        '$locationName: $_selectedType - $description',
        mediaUrl: mediaUrl,
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedMedia = null;
          _selectedLocation = '';
          _descriptionController.clear();
          // Note: The Autocomplete controller is internal to fieldViewBuilder
          // But since we clear _selectedLocation and call setState, it's consistent
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incident submitted to AI pipeline successfully!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          title: const Text(
            'Authentication Required',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SignupScreen(
          onAuthenticated: (name) {
            ref.read(authProvider.notifier).login(name);
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text(
          'Report Incident',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [


              // Form fields
              Text(
                'Incident Details',
                style: AppTextStyles.h2.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 16),

              // Crisis Type Dropdown
              Text('Crisis Type *', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    isExpanded: true,
                    icon: const Icon(LucideIcons.chevronDown, color: AppColors.textMuted, size: 20),
                    items: _crisisTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type, style: AppTextStyles.body),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedType = val;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Location Autocomplete
              Text('Location *', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  final query = textEditingValue.text.trim();
                  if (query.length < 3) {
                    return const Iterable<String>.empty();
                  }

                  // Debounce API calls
                  final completer = Completer<Iterable<String>>();
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 500), () async {
                    try {
                      final results = await _apiService.getPlacePredictions(query);
                      completer.complete(results);
                    } catch (e) {
                      completer.complete(const Iterable<String>.empty());
                    }
                  });
                  return completer.future;
                },
                onSelected: (String selection) {
                  setState(() {
                    _selectedLocation = selection;
                  });
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: AppTextStyles.body,
                    onChanged: (val) {
                      _selectedLocation = val;
                      setState(() {}); // Trigger rebuild for X icon visibility
                    },
                    decoration: InputDecoration(
                      hintText: 'e.g. Sector G-10, Islamabad',
                      prefixIcon: const Icon(LucideIcons.mapPin, color: AppColors.textMuted, size: 18),
                      suffixIcon: controller.text.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 18, color: AppColors.textMuted),
                            onPressed: () {
                              controller.clear();
                              setState(() {
                                _selectedLocation = '';
                              });
                            },
                          )
                        : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.accent, width: 2),
                      ),
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Container(
                        width: MediaQuery.of(context).size.width - 40,
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final option = options.elementAt(index);
                            return ListTile(
                              leading: const Icon(LucideIcons.mapPin, color: AppColors.textMuted, size: 18),
                              title: Text(option, style: AppTextStyles.body),
                              onTap: () {
                                onSelected(option);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Description Input
              Text('Description *', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                style: AppTextStyles.body,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe the situation and visual observations...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.accent, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Media Upload Section
              Text('Media Upload (Images/Videos)', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickMedia,
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    image: _selectedMedia != null
                        ? DecorationImage(
                            image: FileImage(File(_selectedMedia!.path)),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedMedia != null ? LucideIcons.checkCircle : LucideIcons.plusCircle, 
                        color: _selectedMedia != null ? AppColors.successGreen : AppColors.accent, 
                        size: 32
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedMedia != null ? 'Media Selected (Tap to change)' : 'Upload photos or capture live video',
                        style: AppTextStyles.bodyMuted.copyWith(
                          fontSize: 13,
                          color: _selectedMedia != null ? Colors.white : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitIncident,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    shadowColor: AppColors.accent.withOpacity(0.3),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Submit Incident',
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 120), // Space for bottom nav bar
            ],
          ),
        ),
      ),
    );
  }
}
