import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/master_asset_registry_service.dart';
import '../../services/supabase_service.dart';

class AddBusinessScreen extends StatefulWidget {
  final Map<String, dynamic>? existingBusiness;
  const AddBusinessScreen({super.key, this.existingBusiness});

  @override
  State<AddBusinessScreen> createState() => _AddBusinessScreenState();
}

class _AddBusinessScreenState extends State<AddBusinessScreen> {
  final _client = SupabaseService.client;
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isSaving = false;

  // Step 1 - Basic Info
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _regNoCtrl = TextEditingController();
  String _selectedIndustry = 'services';
  String _selectedType = 'sole_proprietorship';
  String _selectedStatus = 'startup';
  DateTime? _dateEstablished;

  // Step 2 - Location & Contact
  final _regionCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  String _selectedCountry = 'Tanzania';

  final _industries = [
    {'value': 'transport', 'label': 'Transport', 'icon': 'directions_bus'},
    {'value': 'agriculture', 'label': 'Agriculture', 'icon': 'agriculture'},
    {'value': 'healthcare', 'label': 'Healthcare', 'icon': 'local_hospital'},
    {'value': 'retail', 'label': 'Retail', 'icon': 'storefront'},
    {'value': 'manufacturing', 'label': 'Manufacturing', 'icon': 'factory'},
    {'value': 'technology', 'label': 'Technology', 'icon': 'computer'},
    {'value': 'real_estate', 'label': 'Real Estate', 'icon': 'apartment'},
    {'value': 'hospitality', 'label': 'Hospitality', 'icon': 'hotel'},
    {'value': 'education', 'label': 'Education', 'icon': 'school'},
    {
      'value': 'services',
      'label': 'Services',
      'icon': 'miscellaneous_services',
    },
    {'value': 'other', 'label': 'Other', 'icon': 'business'},
  ];

  final _businessTypes = [
    'sole_proprietorship',
    'partnership',
    'limited_company',
    'corporation',
    'cooperative',
    'ngo',
  ];
  final _statusOptions = [
    'startup',
    'growing',
    'mature',
    'expanding',
    'closed',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingBusiness != null) {
      final b = widget.existingBusiness!;
      _nameCtrl.text = b['name'] ?? '';
      _descCtrl.text = b['description'] ?? '';
      _regNoCtrl.text = b['registration_no'] ?? '';
      _selectedIndustry = b['industry'] ?? 'services';
      _selectedType = b['business_type'] ?? 'sole_proprietorship';
      _selectedStatus = b['status'] ?? 'startup';
      _regionCtrl.text = b['region'] ?? '';
      _addressCtrl.text = b['address'] ?? '';
      _phoneCtrl.text = b['phone'] ?? '';
      _emailCtrl.text = b['email'] ?? '';
      _websiteCtrl.text = b['website'] ?? '';
      _selectedCountry = b['country'] ?? 'Tanzania';
      if (b['date_established'] != null) {
        _dateEstablished = DateTime.tryParse(b['date_established'] as String);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _regNoCtrl.dispose();
    _regionCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _websiteCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business name is required')),
      );
      return;
    }
    if (_isSaving) return; // prevent double-tap freeze
    setState(() => _isSaving = true);
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not authenticated. Please log in.'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
        return;
      }

      final data = <String, dynamic>{
        'owner_id': userId,
        'name': _nameCtrl.text.trim(),
        'industry': _selectedIndustry,
        'business_type': _selectedType,
        'status': _selectedStatus,
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'registration_no': _regNoCtrl.text.trim().isEmpty
            ? null
            : _regNoCtrl.text.trim(),
        'country': _selectedCountry,
        'region': _regionCtrl.text.trim().isEmpty
            ? null
            : _regionCtrl.text.trim(),
        'address': _addressCtrl.text.trim().isEmpty
            ? null
            : _addressCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'website': _websiteCtrl.text.trim().isEmpty
            ? null
            : _websiteCtrl.text.trim(),
        'date_established': _dateEstablished?.toIso8601String().split('T')[0],
        'is_active': true,
      };

      if (widget.existingBusiness != null) {
        await _client
            .from('businesses')
            .update(data)
            .eq('id', widget.existingBusiness!['id'] as String);
      } else {
        await _client.from('businesses').insert(data);
      }
      // Auto-register in Asset Intelligence
      await MasterAssetRegistryService.instance.autoRegisterAllAssets();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingBusiness != null
                  ? 'Business updated successfully'
                  : 'Business registered successfully',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving business: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _save();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        leading: IconButton(
          onPressed: _prevStep,
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 18,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        title: Text(
          widget.existingBusiness != null
              ? 'Edit Business'
              : 'Register Business',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: AppTheme.outlineLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            minHeight: 3,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [_buildStep1(), _buildStep2(), _buildStep3()],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Basic Info', 'Location', 'Review'];
    return Container(
      color: AppTheme.surfaceLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: steps.asMap().entries.map((e) {
          final isActive = e.key == _currentStep;
          final isDone = e.key < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppTheme.success
                        : isActive
                        ? AppTheme.primary
                        : AppTheme.outlineLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${e.key + 1}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? Colors.white
                                  : AppTheme.mutedLight,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    e.value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? AppTheme.primary : AppTheme.mutedLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (e.key < steps.length - 1)
                  Container(height: 1, width: 16, color: AppTheme.outlineLight),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Business Information'),
          const SizedBox(height: 16),
          _inputField(
            'Business Name *',
            _nameCtrl,
            hint: 'e.g. Nexus Transport Ltd',
          ),
          const SizedBox(height: 14),
          _inputField(
            'Description',
            _descCtrl,
            hint: 'Brief description of your business',
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          _inputField(
            'Registration Number',
            _regNoCtrl,
            hint: 'Official registration number (optional)',
          ),
          const SizedBox(height: 20),
          _sectionTitle('Industry'),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _industries.length,
            itemBuilder: (context, i) {
              final ind = _industries[i];
              final isSelected = _selectedIndustry == ind['value'];
              return GestureDetector(
                onTap: () => setState(() => _selectedIndustry = ind['value']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.outlineLight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: ind['icon']!,
                        color: isSelected ? Colors.white : AppTheme.mutedLight,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          ind['label']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.onSurfaceLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          _sectionTitle('Business Type'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _businessTypes.map((t) {
              final isSelected = _selectedType == t;
              return GestureDetector(
                onTap: () => setState(() => _selectedType = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.outlineLight,
                    ),
                  ),
                  child: Text(
                    t.replaceAll('_', ' ').toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.mutedLight,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Business Status'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _statusOptions.map((s) {
              final isSelected = _selectedStatus == s;
              return GestureDetector(
                onTap: () => setState(() => _selectedStatus = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.outlineLight,
                    ),
                  ),
                  child: Text(
                    s.replaceAll('_', ' ').toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.mutedLight,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Date Established'),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dateEstablished ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _dateEstablished = picked);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: Row(
                children: [
                  const CustomIconWidget(
                    iconName: 'calendar_today',
                    color: AppTheme.mutedLight,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _dateEstablished != null
                        ? '${_dateEstablished!.day}/${_dateEstablished!.month}/${_dateEstablished!.year}'
                        : 'Select date (optional)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: _dateEstablished != null
                          ? AppTheme.onSurfaceLight
                          : AppTheme.mutedLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Location'),
          const SizedBox(height: 16),
          _inputField('Region / City', _regionCtrl, hint: 'e.g. Dar es Salaam'),
          const SizedBox(height: 14),
          _inputField(
            'Address',
            _addressCtrl,
            hint: 'Street address or area',
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          _sectionTitle('Contact Information'),
          const SizedBox(height: 16),
          _inputField(
            'Phone Number',
            _phoneCtrl,
            hint: '+255 XXX XXX XXX',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          _inputField(
            'Email Address',
            _emailCtrl,
            hint: 'business@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _inputField('Website', _websiteCtrl, hint: 'www.yourbusiness.com'),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Review Business Details'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.outlineLight),
            ),
            child: Column(
              children: [
                _reviewRow(
                  'Business Name',
                  _nameCtrl.text.isEmpty ? 'Not set' : _nameCtrl.text,
                ),
                _reviewRow('Industry', _selectedIndustry.replaceAll('_', ' ')),
                _reviewRow('Type', _selectedType.replaceAll('_', ' ')),
                _reviewRow('Status', _selectedStatus.replaceAll('_', ' ')),
                if (_descCtrl.text.isNotEmpty)
                  _reviewRow('Description', _descCtrl.text),
                if (_regNoCtrl.text.isNotEmpty)
                  _reviewRow('Reg. Number', _regNoCtrl.text),
                if (_regionCtrl.text.isNotEmpty)
                  _reviewRow('Region', _regionCtrl.text),
                if (_phoneCtrl.text.isNotEmpty)
                  _reviewRow('Phone', _phoneCtrl.text),
                if (_emailCtrl.text.isNotEmpty)
                  _reviewRow('Email', _emailCtrl.text),
                if (_dateEstablished != null)
                  _reviewRow(
                    'Established',
                    '${_dateEstablished!.day}/${_dateEstablished!.month}/${_dateEstablished!.year}',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const CustomIconWidget(
                  iconName: 'info',
                  color: AppTheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'After registering, you can add branches, employees, and start tracking transactions.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.mutedLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.onSurfaceLight,
      ),
    );
  }

  Widget _inputField(
    String label,
    TextEditingController ctrl, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.mutedLight,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.onSurfaceLight,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.mutedLight.withAlpha(120),
            ),
            filled: true,
            fillColor: AppTheme.surfaceLight,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.outlineLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.outlineLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(top: BorderSide(color: AppTheme.outlineLight)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: AppTheme.outlineLight),
                ),
                child: Text(
                  'Back',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.mutedLight,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _currentStep == 2
                          ? (widget.existingBusiness != null
                                ? 'Update Business'
                                : 'Register Business')
                          : 'Continue',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
