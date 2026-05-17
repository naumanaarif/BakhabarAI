import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // Form Fields
  String _selectedType = 'Flood';
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
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
    super.dispose();
  }

  void _submitIncident() async {
    final description = _descriptionController.text.trim();
    final locationName = _locationController.text.trim();

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
      // Simulate submission to the backend SignalCollectorAgent
      await _apiService.submitReport('$locationName: $_selectedType - $description');
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incident submitted to AI pipeline successfully!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        // Clear fields
        _descriptionController.clear();
        _locationController.clear();
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
          onAuthenticated: () {
            ref.read(authProvider.notifier).login('Ahmed');
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
              // Draft Warning Alert
              Container(
                decoration: BoxDecoration(
                  color: AppColors.severityMedium.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.severityMedium.withOpacity(0.3)),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertCircle, color: AppColors.severityMedium, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unsubmitted Draft',
                            style: AppTextStyles.label.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.severityMedium,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'You have a draft report from 2 hrs ago.',
                            style: AppTextStyles.bodyMuted.copyWith(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

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

              // Location Input
              Text('Location *', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _locationController,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: 'e.g. Sector G-10, Islamabad',
                  prefixIcon: const Icon(LucideIcons.mapPin, color: AppColors.textMuted, size: 18),
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
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Media picker simulated successfully.'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                },
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.plusCircle, color: AppColors.accent, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Upload photos or capture live video',
                        style: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Supports PNG, JPG, MP4 (Max 15MB)',
                        style: AppTextStyles.labelMuted.copyWith(fontSize: 11),
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
