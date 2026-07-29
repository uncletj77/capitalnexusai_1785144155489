import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../services/universal_registration_service.dart';
import '../transaction_preview_screen/transaction_preview_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UNIVERSAL REGISTRATION WIZARD (URW)
// Single authoritative entry point for ALL financial records in CNA.
// Implements the 9-stage Transaction Intelligence Engine pipeline.
// ─────────────────────────────────────────────────────────────────────────────

class UniversalRegistrationWizardScreen extends StatefulWidget {
  final RegistrationCategory? initialCategory;
  final String? initialType;

  const UniversalRegistrationWizardScreen({
    super.key,
    this.initialCategory,
    this.initialType,
  });

  @override
  State<UniversalRegistrationWizardScreen> createState() =>
      _UniversalRegistrationWizardScreenState();
}

class _UniversalRegistrationWizardScreenState
    extends State<UniversalRegistrationWizardScreen>
    with TickerProviderStateMixin {
  final _ure = UniversalRegistrationService.instance;
  late AnimationController _stepAnimController;
  late Animation<double> _stepFadeAnim;

  // Wizard state
  int _currentStep =
      0; // 0=category, 1=type, 2=ownership, 3=relationship, 4=form, 5=validate
  RegistrationCategory? _selectedCategory;
  String? _selectedType;
  OwnershipType _ownershipType = OwnershipType.personal;
  Map<String, dynamic> _formData = {};
  Map<String, dynamic> _relationships = {};
  Map<String, String> _validationErrors = {};
  bool _isLoading = false;
  bool _hasDraft = false;
  Map<String, dynamic>? _draftData;

  // Lookup data
  final Map<String, List<Map<String, dynamic>>> _lookupCache = {};

  // Form controllers
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, DateTime?> _dateValues = {};
  final Map<String, String?> _selectValues = {};

  @override
  void initState() {
    super.initState();
    _stepAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _stepFadeAnim = CurvedAnimation(
      parent: _stepAnimController,
      curve: Curves.easeOut,
    );
    _stepAnimController.forward();

    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory;
      _currentStep = 1;
      if (widget.initialType != null) {
        _selectedType = widget.initialType;
        _currentStep = 2;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForDraft());
  }

  @override
  void dispose() {
    _stepAnimController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _checkForDraft() async {
    if (_selectedCategory != null && _selectedType != null) {
      final draft = await _ure.loadDraft(
        category: _selectedCategory!,
        registrationType: _selectedType!,
      );
      if (draft != null && mounted) {
        setState(() {
          _hasDraft = true;
          _draftData = draft;
        });
        _showDraftRecoveryDialog(draft);
      }
    }
  }

  void _showDraftRecoveryDialog(Map<String, dynamic> draft) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.warningContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const CustomIconWidget(
                iconName: 'restore',
                color: AppTheme.warning,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Unfinished Registration',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceLight,
              ),
            ),
          ],
        ),
        content: Text(
          'You have an unfinished registration. Would you like to continue where you left off?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppTheme.mutedLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _ure.deleteDraft(_selectedCategory!, _selectedType!);
            },
            child: Text(
              'Start Fresh',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.mutedLight),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _restoreDraft(draft);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Continue',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _restoreDraft(Map<String, dynamic> draft) {
    final formData = Map<String, dynamic>.from(
      draft['form_data'] as Map? ?? {},
    );
    final relationships = Map<String, dynamic>.from(
      draft['selected_relationships'] as Map? ?? {},
    );
    final step = (draft['current_step'] as int?) ?? 2;

    setState(() {
      _formData = formData;
      _relationships = relationships;
      _currentStep = step;
    });

    // Restore controllers
    for (final entry in formData.entries) {
      if (!_controllers.containsKey(entry.key)) {
        _controllers[entry.key] = TextEditingController(
          text: entry.value?.toString() ?? '',
        );
      } else {
        _controllers[entry.key]!.text = entry.value?.toString() ?? '';
      }
    }
  }

  void _animateToStep(int step) {
    _stepAnimController.reset();
    setState(() => _currentStep = step);
    _stepAnimController.forward();
  }

  Future<void> _saveDraftSilently() async {
    if (_selectedCategory == null || _selectedType == null) return;
    await _ure.saveDraft(
      category: _selectedCategory!,
      registrationType: _selectedType!,
      currentStep: _currentStep,
      formData: _formData,
      selectedRelationships: _relationships,
    );
  }

  Future<void> _loadLookup(String tableName) async {
    if (_lookupCache.containsKey(tableName)) return;
    setState(() => _isLoading = true);
    final data = await _ure.lookupEntities(tableName);
    if (mounted) {
      setState(() {
        _lookupCache[tableName] = data;
        _isLoading = false;
      });
    }
  }

  void _preloadFormLookups() {
    if (_selectedType == null) return;
    final fields = RegistrationFormSchema.getFields(_selectedType!);
    for (final f in fields) {
      if (f.type == 'lookup' && f.lookupTable != null) {
        _loadLookup(f.lookupTable!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: FadeTransition(
              opacity: _stepFadeAnim,
              child: _buildCurrentStep(),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final stepTitles = [
      'What to Register',
      'Select Type',
      'Ownership',
      'Relationships',
      'Details',
      'Review',
    ];
    final title = _currentStep < stepTitles.length
        ? stepTitles[_currentStep]
        : 'Register';

    return AppBar(
      backgroundColor: AppTheme.surfaceLight,
      elevation: 0,
      leading: IconButton(
        icon: const CustomIconWidget(
          iconName: 'arrow_back',
          color: AppTheme.onSurfaceLight,
          size: 22,
        ),
        onPressed: () {
          if (_currentStep > 0) {
            _saveDraftSilently();
            _animateToStep(_currentStep - 1);
          } else {
            context.pop();
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          Text(
            'Step ${_currentStep + 1} of 6',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppTheme.mutedLight,
            ),
          ),
        ],
      ),
      actions: [
        if (_currentStep >= 2)
          TextButton(
            onPressed: () {
              _saveDraftSilently();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Draft saved. You can continue later.',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white),
                  ),
                  backgroundColor: AppTheme.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            child: Text(
              'Save Draft',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Container(
      color: AppTheme.surfaceLight,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          Row(
            children: List.generate(6, (i) {
              final isCompleted = i < _currentStep;
              final isCurrent = i == _currentStep;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 5 ? 4 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.primary
                        : isCurrent
                        ? AppTheme.primaryLight
                        : AppTheme.outlineLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildCategoryStep();
      case 1:
        return _buildTypeStep();
      case 2:
        return _buildOwnershipStep();
      case 3:
        return _buildRelationshipStep();
      case 4:
        return _buildFormStep();
      case 5:
        return _buildValidationStep();
      default:
        return _buildCategoryStep();
    }
  }

  // ─── STEP 0: CATEGORY SELECTION ─────────────────────────────────────────────

  Widget _buildCategoryStep() {
    final categories = [
      RegistrationCategory.transaction,
      RegistrationCategory.business,
      RegistrationCategory.investment,
      RegistrationCategory.asset,
      RegistrationCategory.loan,
      RegistrationCategory.organization,
    ];

    final colors = {
      RegistrationCategory.transaction: const Color(0xFF10B981),
      RegistrationCategory.business: const Color(0xFF059669),
      RegistrationCategory.investment: const Color(0xFF2D9CDB),
      RegistrationCategory.asset: const Color(0xFF8B5CF6),
      RegistrationCategory.loan: const Color(0xFFEF4444),
      RegistrationCategory.organization: const Color(0xFF1A5F7A),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'What would you like to register?',
            'Select the category that best describes what you are recording.',
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: categories.length,
            itemBuilder: (ctx, i) {
              final cat = categories[i];
              final color = colors[cat]!;
              final label = RegistrationCategory_.labels[cat]!;
              final icon = RegistrationCategory_.icons[cat]!;
              final isSelected = _selectedCategory == cat;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedCategory = cat);
                  Future.delayed(const Duration(milliseconds: 150), () {
                    _animateToStep(1);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withAlpha(20)
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? color : AppTheme.outlineLight,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withAlpha(30),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [
                            const BoxShadow(
                              color: Color(0x08000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withAlpha(18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CustomIconWidget(
                          iconName: icon,
                          color: color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? color : AppTheme.onSurfaceLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── STEP 1: TYPE SELECTION ──────────────────────────────────────────────────

  Widget _buildTypeStep() {
    if (_selectedCategory == null) {
      _animateToStep(0);
      return const SizedBox.shrink();
    }

    final types = RegistrationTypes.byCategory[_selectedCategory!] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Select the type',
            'Choose the specific type of ${RegistrationCategory_.labels[_selectedCategory!]?.toLowerCase()} you are registering.',
          ),
          const SizedBox(height: 16),
          ...types.map((t) {
            final isSelected = _selectedType == t['key'];
            final color = Color(int.parse(t['color']!));
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedType = t['key']);
                Future.delayed(const Duration(milliseconds: 150), () {
                  _animateToStep(2);
                  _checkForDraft();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withAlpha(15)
                      : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : AppTheme.outlineLight,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withAlpha(18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: t['icon']!,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t['label']!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? color : AppTheme.onSurfaceLight,
                        ),
                      ),
                    ),
                    if (isSelected)
                      CustomIconWidget(
                        iconName: 'check_circle',
                        color: color,
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── STEP 2: OWNERSHIP ───────────────────────────────────────────────────────

  Widget _buildOwnershipStep() {
    final options = [
      {
        'type': OwnershipType.personal,
        'label': 'Personal',
        'icon': 'person',
        'desc': 'Belongs to you personally',
      },
      {
        'type': OwnershipType.business,
        'label': 'Business',
        'icon': 'business_center',
        'desc': 'Belongs to a registered business',
      },
      {
        'type': OwnershipType.organization,
        'label': 'Organization',
        'icon': 'corporate_fare',
        'desc': 'Belongs to an organization',
      },
      {
        'type': OwnershipType.investment,
        'label': 'Investment',
        'icon': 'trending_up',
        'desc': 'Part of an investment portfolio',
      },
      {
        'type': OwnershipType.joint,
        'label': 'Joint',
        'icon': 'group',
        'desc': 'Shared ownership',
      },
      {
        'type': OwnershipType.other,
        'label': 'Other',
        'icon': 'more_horiz',
        'desc': 'Other ownership type',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Who owns this?',
            'Ownership determines how this record is linked across all modules.',
          ),
          const SizedBox(height: 16),
          ...options.map((o) {
            final type = o['type'] as OwnershipType;
            final isSelected = _ownershipType == type;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _ownershipType = type);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryContainer
                      : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.outlineLight,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withAlpha(20)
                            : AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: o['icon'] as String,
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.mutedLight,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o['label'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.onSurfaceLight,
                            ),
                          ),
                          Text(
                            o['desc'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.mutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const CustomIconWidget(
                        iconName: 'check_circle',
                        color: AppTheme.primary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          _buildNextButton('Continue', () => _animateToStep(3)),
        ],
      ),
    );
  }

  // ─── STEP 3: RELATIONSHIP DISCOVERY ─────────────────────────────────────────

  Widget _buildRelationshipStep() {
    // Determine which lookups to show based on ownership and type
    final lookupTables = <String>[];
    if (_ownershipType == OwnershipType.business) {
      lookupTables.add('businesses');
    }
    if (_ownershipType == OwnershipType.investment) {
      lookupTables.add('investments');
    }

    // Pre-load
    for (final t in lookupTables) {
      _loadLookup(t);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Where does this belong?',
            'Link this record to an existing entity, or create a new one.',
          ),
          const SizedBox(height: 16),
          if (lookupTables.isEmpty)
            _buildInfoCard(
              'Personal Record',
              'This record will be registered under your personal profile.',
              'person',
              AppTheme.primary,
            )
          else
            ...lookupTables.map((table) => _buildRelationshipLookup(table)),
          const SizedBox(height: 16),
          _buildNextButton('Continue', () {
            _animateToStep(4);
            _preloadFormLookups();
          }),
        ],
      ),
    );
  }

  Widget _buildRelationshipLookup(String tableName) {
    final entities = _lookupCache[tableName] ?? [];
    final tableLabels = {
      'businesses': 'Business',
      'investments': 'Investment',
      'organizations': 'Organization',
    };
    final label = tableLabels[tableName] ?? tableName;
    final selectedId = _relationships['${tableName}_id'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select $label',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (entities.isEmpty)
          _buildCreateNewCard(label, tableName)
        else ...[
          ...entities.map((e) {
            final id = e['id'] as String?;
            final name = _ure.getEntityDisplayName(tableName, e);
            final isSelected = selectedId == id;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _relationships['${tableName}_id'] = id;
                  if (tableName == 'businesses') {
                    _formData['related_business_id'] = id;
                  } else if (tableName == 'investments') {
                    _formData['related_investment_id'] = id;
                  }
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryContainer
                      : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.outlineLight,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.onSurfaceLight,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const CustomIconWidget(
                        iconName: 'check_circle',
                        color: AppTheme.primary,
                        size: 18,
                      ),
                  ],
                ),
              ),
            );
          }),
          _buildCreateNewCard(label, tableName),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCreateNewCard(String label, String tableName) {
    return GestureDetector(
      onTap: () {
        // Navigate to create new entity, then return
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No $label found. You can create one from the $label module and return here.',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
            backgroundColor: AppTheme.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: 'Continue Anyway',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.outlineLight,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            const CustomIconWidget(
              iconName: 'add_circle_outline',
              color: AppTheme.primary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'Create New $label',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── STEP 4: DYNAMIC FORM ────────────────────────────────────────────────────

  Widget _buildFormStep() {
    if (_selectedType == null) {
      _animateToStep(1);
      return const SizedBox.shrink();
    }

    final fields = RegistrationFormSchema.getFields(_selectedType!);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Enter Details',
            'Fill in the information below. Fields marked with * are required.',
          ),
          const SizedBox(height: 16),
          ...fields.map((field) => _buildFormField(field)),
          const SizedBox(height: 16),
          _buildNextButton('Review & Confirm', () async {
            // Save form data from controllers
            for (final field in fields) {
              if (_controllers.containsKey(field.key)) {
                _formData[field.key] = _controllers[field.key]!.text;
              }
              if (_dateValues.containsKey(field.key) &&
                  _dateValues[field.key] != null) {
                _formData[field.key] = _dateValues[field.key]!
                    .toIso8601String()
                    .split('T')[0];
              }
              if (_selectValues.containsKey(field.key)) {
                _formData[field.key] = _selectValues[field.key];
              }
            }

            // Validate
            final result = await _ure.validate(
              registrationType: _selectedType!,
              formData: _formData,
              relationships: _relationships,
            );

            if (result.isValid) {
              _animateToStep(5);
            } else {
              setState(() => _validationErrors = result.errors);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Please fix ${result.errors.length} error(s) before continuing.',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white),
                  ),
                  backgroundColor: AppTheme.danger,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }
          }),
        ],
      ),
    );
  }

  Widget _buildFormField(RegistrationField field) {
    final error = _validationErrors[field.key];

    switch (field.type) {
      case 'text':
      case 'number':
      case 'currency':
      case 'textarea':
        if (!_controllers.containsKey(field.key)) {
          _controllers[field.key] = TextEditingController(
            text: _formData[field.key]?.toString() ?? field.defaultValue ?? '',
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel(field),
              const SizedBox(height: 6),
              TextField(
                controller: _controllers[field.key],
                keyboardType: field.type == 'number' || field.type == 'currency'
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
                maxLines: field.type == 'textarea' ? 3 : 1,
                onChanged: (v) {
                  _formData[field.key] = v;
                  if (error != null) {
                    setState(() => _validationErrors.remove(field.key));
                  }
                },
                decoration: _inputDecoration(
                  hint: field.hint ?? 'Enter ${field.label.toLowerCase()}',
                  prefix: field.type == 'currency' ? 'TZS' : null,
                  error: error,
                ),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppTheme.onSurfaceLight,
                ),
              ),
              if (error != null) _buildErrorText(error),
            ],
          ),
        );

      case 'date':
        final dateVal =
            _dateValues[field.key] ??
            ((_formData[field.key] != null)
                ? DateTime.tryParse(_formData[field.key].toString())
                : null);
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel(field),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dateVal ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppTheme.primary,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setState(() {
                      _dateValues[field.key] = picked;
                      _formData[field.key] = picked.toIso8601String().split(
                        'T',
                      )[0];
                      _validationErrors.remove(field.key);
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: error != null
                          ? AppTheme.danger
                          : AppTheme.outlineLight,
                    ),
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
                        dateVal != null
                            ? '${dateVal.day}/${dateVal.month}/${dateVal.year}'
                            : 'Select date',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: dateVal != null
                              ? AppTheme.onSurfaceLight
                              : AppTheme.mutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (error != null) _buildErrorText(error),
            ],
          ),
        );

      case 'select':
        final currentVal =
            _selectValues[field.key] ??
            _formData[field.key]?.toString() ??
            field.defaultValue;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel(field),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: error != null
                        ? AppTheme.danger
                        : AppTheme.outlineLight,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: currentVal,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    hint: Text(
                      'Select ${field.label.toLowerCase()}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppTheme.mutedLight,
                      ),
                    ),
                    items: (field.options ?? []).map((opt) {
                      return DropdownMenuItem<String>(
                        value: opt['key'],
                        child: Text(
                          opt['label']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppTheme.onSurfaceLight,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectValues[field.key] = v;
                        _formData[field.key] = v;
                        _validationErrors.remove(field.key);
                      });
                    },
                  ),
                ),
              ),
              if (error != null) _buildErrorText(error),
            ],
          ),
        );

      case 'lookup':
        final tableName = field.lookupTable!;
        final entities = _lookupCache[tableName] ?? [];
        final selectedId = _formData[field.key]?.toString();

        // Trigger load
        if (!_lookupCache.containsKey(tableName)) {
          _loadLookup(tableName);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel(field),
              const SizedBox(height: 6),
              if (_isLoading && entities.isEmpty)
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.outlineLight),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (entities.isEmpty)
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'No ${field.label} found. Create one first.',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: AppTheme.warning,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.warningContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.warning.withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        const CustomIconWidget(
                          iconName: 'warning_amber',
                          color: AppTheme.warning,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'No ${field.label} found. Tap to create one.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppTheme.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: error != null
                          ? AppTheme.danger
                          : AppTheme.outlineLight,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedId,
                      isExpanded: true,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      hint: Text(
                        'Select ${field.label.toLowerCase()}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppTheme.mutedLight,
                        ),
                      ),
                      items: entities.map((e) {
                        final id = e['id'] as String?;
                        final name = _ure.getEntityDisplayName(tableName, e);
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: AppTheme.onSurfaceLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        setState(() {
                          _formData[field.key] = v;
                          _validationErrors.remove(field.key);
                        });
                      },
                    ),
                  ),
                ),
              if (error != null) _buildErrorText(error),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // ─── STEP 5: VALIDATION & REVIEW SUMMARY ────────────────────────────────────

  Widget _buildValidationStep() {
    if (_selectedCategory == null || _selectedType == null) {
      _animateToStep(0);
      return const SizedBox.shrink();
    }

    final preview = _ure.buildPreview(
      category: _selectedCategory!,
      registrationType: _selectedType!,
      formData: _formData,
      relationships: _relationships,
      ownershipType: _ownershipType,
    );

    final affectedModules = List<String>.from(
      preview['affected_modules'] as List? ?? [],
    );
    final financialImpact = Map<String, String>.from(
      preview['financial_impact'] as Map? ?? {},
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Review & Confirm',
            'Review all details before saving. You can go back to make changes.',
          ),
          const SizedBox(height: 16),

          // Summary card
          _buildPreviewCard(preview),
          const SizedBox(height: 12),

          // Financial impact
          if (financialImpact.isNotEmpty) ...[
            _buildSectionTitle('Financial Impact'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outlineLight),
              ),
              child: Column(
                children: financialImpact.entries
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              e.key,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppTheme.mutedLight,
                              ),
                            ),
                            Text(
                              e.value,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: e.value.startsWith('+')
                                    ? AppTheme.success
                                    : e.value.startsWith('-')
                                    ? AppTheme.danger
                                    : AppTheme.onSurfaceLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Modules that will sync
          _buildSectionTitle('Modules that will update'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: affectedModules
                .map(
                  (m) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      m,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _commitRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Confirm & Save',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _animateToStep(4),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppTheme.outlineLight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Edit Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mutedLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(Map<String, dynamic> preview) {
    final formData = Map<String, dynamic>.from(
      preview['form_data'] as Map? ?? {},
    );
    final typeLabel =
        RegistrationTypes.byCategory[_selectedCategory!]?.firstWhere(
          (t) => t['key'] == _selectedType,
          orElse: () => {'label': _selectedType ?? ''},
        )['label'] ??
        '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  typeLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _ownershipType.name.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.outlineLight),
          const SizedBox(height: 8),
          ...formData.entries
              .where((e) => e.value != null && e.value.toString().isNotEmpty)
              .take(8)
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(
                          _fieldKeyToLabel(e.key),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.mutedLight,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          e.value.toString(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurfaceLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
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

  String _fieldKeyToLabel(String key) {
    return key
        .replaceAll('_id', '')
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  // ─── COMMIT ──────────────────────────────────────────────────────────────────

  Future<void> _commitRegistration() async {
    if (_selectedCategory == null || _selectedType == null) return;

    setState(() => _isLoading = true);

    final result = await _ure.commit(
      category: _selectedCategory!,
      registrationType: _selectedType!,
      formData: _formData,
      relationships: _relationships,
      ownershipType: _ownershipType,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      // Navigate to success screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionPreviewScreen(
            commitResult: result,
            registrationCategory: _selectedCategory!,
            registrationType: _selectedType!,
            formData: _formData,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ?? 'Registration failed. Please try again.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.mutedLight,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.onSurfaceLight,
        ),
      ),
    );
  }

  Widget _buildFieldLabel(RegistrationField field) {
    return RichText(
      text: TextSpan(
        text: field.label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.onSurfaceLight,
        ),
        children: field.required
            ? [
                TextSpan(
                  text: ' *',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.danger),
                ),
              ]
            : [],
      ),
    );
  }

  Widget _buildErrorText(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        error,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          color: AppTheme.danger,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hint,
    String? prefix,
    String? error,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: AppTheme.mutedLight,
      ),
      prefixText: prefix != null ? '$prefix ' : null,
      prefixStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: AppTheme.mutedLight,
      ),
      filled: true,
      fillColor: AppTheme.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.outlineLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: error != null ? AppTheme.danger : AppTheme.outlineLight,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: error != null ? AppTheme.danger : AppTheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.danger),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String subtitle,
    String icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        children: [
          CustomIconWidget(iconName: icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.mutedLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
