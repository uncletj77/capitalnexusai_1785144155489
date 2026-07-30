import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class AddAssetScreen extends StatefulWidget {
  final Map<String, dynamic>? existingAsset;
  const AddAssetScreen({super.key, this.existingAsset});

  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _client = SupabaseService.client;
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isSaving = false;

  // Form controllers
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _purchasePriceCtrl = TextEditingController();
  final _currentValueCtrl = TextEditingController();
  final _monthlyIncomeCtrl = TextEditingController();
  final _monthlyExpensesCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _category = 'fixed';
  String _assetType = 'other';
  String _condition = 'good';
  String _fundingSource = 'cash';
  String _ownershipType = 'individual';
  DateTime? _purchaseDate;
  int _usefulLife = 10;
  double _depreciationRate = 10.0;

  bool get _isEditing => widget.existingAsset != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final a = widget.existingAsset!;
      _nameCtrl.text = a['asset_name'] ?? '';
      _descCtrl.text = a['description'] ?? '';
      _purchasePriceCtrl.text = (a['purchase_price'] ?? 0).toString();
      _currentValueCtrl.text = (a['current_value'] ?? 0).toString();
      _monthlyIncomeCtrl.text = (a['monthly_income'] ?? 0).toString();
      _monthlyExpensesCtrl.text = (a['monthly_expenses'] ?? 0).toString();
      _regionCtrl.text = a['region'] ?? '';
      _addressCtrl.text = a['address'] ?? '';
      _ownerNameCtrl.text = a['owner_name'] ?? '';
      _notesCtrl.text = a['notes'] ?? '';
      _category = a['asset_category'] ?? 'fixed';
      _assetType = a['asset_type'] ?? 'other';
      _condition = a['asset_condition'] ?? 'good';
      _fundingSource = a['funding_source'] ?? 'cash';
      _ownershipType = a['ownership_type'] ?? 'individual';
      _usefulLife = a['useful_life_years'] ?? 10;
      _depreciationRate = (a['depreciation_rate'] ?? 10.0).toDouble();
      if (a['purchase_date'] != null) {
        _purchaseDate = DateTime.tryParse(a['purchase_date']);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _currentValueCtrl.dispose();
    _monthlyIncomeCtrl.dispose();
    _monthlyExpensesCtrl.dispose();
    _regionCtrl.dispose();
    _addressCtrl.dispose();
    _ownerNameCtrl.dispose();
    _notesCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveAsset() async {
    setState(() => _isSaving = true);
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final data = {
        'user_id': userId,
        'asset_name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'asset_category': _category,
        'asset_type': _assetType,
        'asset_condition': _condition,
        'funding_source': _fundingSource,
        'ownership_type': _ownershipType,
        'owner_name': _ownerNameCtrl.text.trim().isEmpty
            ? 'Me'
            : _ownerNameCtrl.text.trim(),
        'purchase_price':
            double.tryParse(_purchasePriceCtrl.text.replaceAll(',', '')) ?? 0,
        'current_value':
            double.tryParse(_currentValueCtrl.text.replaceAll(',', '')) ?? 0,
        'monthly_income':
            double.tryParse(_monthlyIncomeCtrl.text.replaceAll(',', '')) ?? 0,
        'monthly_expenses':
            double.tryParse(_monthlyExpensesCtrl.text.replaceAll(',', '')) ?? 0,
        'region': _regionCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'useful_life_years': _usefulLife,
        'depreciation_rate': _depreciationRate,
        'notes': _notesCtrl.text.trim(),
        'purchase_date': _purchaseDate?.toIso8601String().split('T')[0],
        'asset_status': 'active',
        'lifecycle_stage': 'active',
      };

      if (_isEditing) {
        await _client
            .from('assets')
            .update(data)
            .eq('id', widget.existingAsset!['id']);
      } else {
        await _client.from('assets').insert(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Asset updated successfully'
                  : 'Asset added successfully',
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
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _saveAsset();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = ['Basic Info', 'Financial', 'Ownership', 'Location'];

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: const CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.onSurfaceLight,
            size: 22,
          ),
          onPressed: _prevStep,
        ),
        title: Text(
          _isEditing ? 'Edit Asset' : 'Add Asset',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppTheme.onSurfaceLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildStepIndicator(steps, theme),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStep1(theme),
          _buildStep2(theme),
          _buildStep3(theme),
          _buildStep4(theme),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(theme, steps),
    );
  }

  Widget _buildStepIndicator(List<String> steps, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDone || isActive
                              ? AppTheme.primary
                              : AppTheme.outlineLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[i],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isActive
                              ? AppTheme.primary
                              : AppTheme.mutedLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (i < steps.length - 1) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Asset Information'),
          const SizedBox(height: 16),
          _InputField(
            controller: _nameCtrl,
            label: 'Asset Name',
            hint: 'e.g. Toyota Hiace Bus',
            icon: 'label',
          ),
          const SizedBox(height: 14),
          _InputField(
            controller: _descCtrl,
            label: 'Description',
            hint: 'Brief description of this asset',
            icon: 'description',
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          _SectionTitle('Category'),
          const SizedBox(height: 12),
          _buildCategoryGrid(theme),
          const SizedBox(height: 20),
          _SectionTitle('Asset Type'),
          const SizedBox(height: 12),
          _buildTypeDropdown(theme),
          const SizedBox(height: 20),
          _SectionTitle('Condition'),
          const SizedBox(height: 12),
          _buildConditionRow(theme),
        ],
      ),
    );
  }

  Widget _buildStep2(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Financial Details'),
          const SizedBox(height: 16),
          _InputField(
            controller: _purchasePriceCtrl,
            label: 'Purchase Price (TZS)',
            hint: '0',
            icon: 'payments',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          _InputField(
            controller: _currentValueCtrl,
            label: 'Current Value (TZS)',
            hint: '0',
            icon: 'trending_up',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _purchaseDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => _purchaseDate = d);
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
                    color: AppTheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _purchaseDate == null
                        ? 'Select Purchase Date'
                        : '${_purchaseDate!.day}/${_purchaseDate!.month}/${_purchaseDate!.year}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _purchaseDate == null
                          ? AppTheme.mutedLight
                          : AppTheme.onSurfaceLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle('Funding Source'),
          const SizedBox(height: 12),
          _buildFundingSourceRow(theme),
          const SizedBox(height: 20),
          _SectionTitle('Income & Expenses'),
          const SizedBox(height: 12),
          _InputField(
            controller: _monthlyIncomeCtrl,
            label: 'Monthly Income Generated (TZS)',
            hint: '0',
            icon: 'add_circle',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          _InputField(
            controller: _monthlyExpensesCtrl,
            label: 'Monthly Operating Costs (TZS)',
            hint: '0',
            icon: 'remove_circle',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          _SectionTitle('Depreciation'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Useful Life: $_usefulLife years',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedLight,
                      ),
                    ),
                    Slider(
                      value: _usefulLife.toDouble(),
                      min: 1,
                      max: 50,
                      divisions: 49,
                      activeColor: AppTheme.primary,
                      onChanged: (v) => setState(() => _usefulLife = v.round()),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Depreciation: ${_depreciationRate.toStringAsFixed(0)}%/yr',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedLight,
                      ),
                    ),
                    Slider(
                      value: _depreciationRate,
                      min: 0,
                      max: 50,
                      divisions: 50,
                      activeColor: AppTheme.warning,
                      onChanged: (v) => setState(() => _depreciationRate = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Ownership Details'),
          const SizedBox(height: 16),
          _buildOwnershipTypeRow(theme),
          const SizedBox(height: 14),
          _InputField(
            controller: _ownerNameCtrl,
            label: 'Owner Name',
            hint: 'Your name or business name',
            icon: 'person',
          ),
          const SizedBox(height: 14),
          _InputField(
            controller: _notesCtrl,
            label: 'Notes (optional)',
            hint: 'Any additional notes about this asset',
            icon: 'notes',
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildStep4(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Location'),
          const SizedBox(height: 16),
          _InputField(
            controller: _regionCtrl,
            label: 'Region / City',
            hint: 'e.g. Dar es Salaam',
            icon: 'location_city',
          ),
          const SizedBox(height: 14),
          _InputField(
            controller: _addressCtrl,
            label: 'Full Address',
            hint: 'Street address or area',
            icon: 'location_on',
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          _SectionTitle('Review Summary'),
          const SizedBox(height: 12),
          _buildReviewCard(theme),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ThemeData theme) {
    final purchasePrice =
        double.tryParse(_purchasePriceCtrl.text.replaceAll(',', '')) ?? 0;
    final currentValue =
        double.tryParse(_currentValueCtrl.text.replaceAll(',', '')) ?? 0;
    final income =
        double.tryParse(_monthlyIncomeCtrl.text.replaceAll(',', '')) ?? 0;
    final expenses =
        double.tryParse(_monthlyExpensesCtrl.text.replaceAll(',', '')) ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withAlpha(60)),
      ),
      child: Column(
        children: [
          _ReviewRow('Name', _nameCtrl.text.isEmpty ? '—' : _nameCtrl.text),
          _ReviewRow('Category', _category),
          _ReviewRow('Type', _assetType),
          _ReviewRow('Condition', _condition),
          _ReviewRow(
            'Purchase Price',
            'TSh ${purchasePrice.toStringAsFixed(0)}',
          ),
          _ReviewRow('Current Value', 'TSh ${currentValue.toStringAsFixed(0)}'),
          _ReviewRow('Monthly Income', 'TSh ${income.toStringAsFixed(0)}'),
          _ReviewRow('Monthly Costs', 'TSh ${expenses.toStringAsFixed(0)}'),
          _ReviewRow(
            'Net Monthly',
            'TSh ${(income - expenses).toStringAsFixed(0)}',
          ),
          _ReviewRow('Funding', _fundingSource),
          _ReviewRow('Ownership', _ownershipType),
          _ReviewRow(
            'Location',
            _regionCtrl.text.isEmpty ? '—' : _regionCtrl.text,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(ThemeData theme) {
    final cats = [
      {
        'key': 'fixed',
        'label': 'Fixed',
        'icon': 'home_work',
        'color': AppTheme.fixedAssetColor,
      },
      {
        'key': 'current',
        'label': 'Current',
        'icon': 'account_balance_wallet',
        'color': AppTheme.currentAssetColor,
      },
      {
        'key': 'permanent_strategic',
        'label': 'Strategic',
        'icon': 'star',
        'color': AppTheme.appreciatingColor,
      },
      {
        'key': 'temporary',
        'label': 'Temporary',
        'icon': 'swap_horiz',
        'color': AppTheme.depreciatingColor,
      },
    ];
    return Row(
      children: cats.map((c) {
        final isSelected = _category == c['key'];
        final color = c['color'] as Color;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _category = c['key'] as String),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color.withAlpha(26) : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : AppTheme.outlineLight,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  CustomIconWidget(
                    iconName: c['icon'] as String,
                    color: isSelected ? color : AppTheme.mutedLight,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c['label'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : AppTheme.mutedLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTypeDropdown(ThemeData theme) {
    final types = [
      'land',
      'building',
      'vehicle',
      'machinery',
      'equipment',
      'inventory',
      'cash',
      'receivable',
      'investment',
      'business',
      'intangible',
      'other',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _assetType,
          isExpanded: true,
          icon: const CustomIconWidget(
            iconName: 'expand_more',
            color: AppTheme.mutedLight,
            size: 20,
          ),
          items: types
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(
                    t[0].toUpperCase() + t.substring(1).replaceAll('_', ' '),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurfaceLight,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _assetType = v!),
        ),
      ),
    );
  }

  Widget _buildConditionRow(ThemeData theme) {
    final conditions = [
      {'key': 'new', 'label': 'New', 'color': AppTheme.success},
      {'key': 'good', 'label': 'Good', 'color': AppTheme.primary},
      {'key': 'fair', 'label': 'Fair', 'color': AppTheme.warning},
      {'key': 'poor', 'label': 'Poor', 'color': AppTheme.error},
      {
        'key': 'requires_replacement',
        'label': 'Replace',
        'color': const Color(0xFF7C3AED),
      },
    ];
    return Wrap(
      spacing: 8,
      children: conditions.map((c) {
        final isSelected = _condition == c['key'];
        final color = c['color'] as Color;
        return GestureDetector(
          onTap: () => setState(() => _condition = c['key'] as String),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color.withAlpha(26) : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isSelected ? color : AppTheme.outlineLight,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              c['label'] as String,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : AppTheme.mutedLight,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFundingSourceRow(ThemeData theme) {
    final sources = [
      {'key': 'cash', 'label': 'Cash', 'icon': 'payments'},
      {'key': 'loan', 'label': 'Loan', 'icon': 'credit_card'},
      {'key': 'investment', 'label': 'Investment', 'icon': 'trending_up'},
      {'key': 'business_income', 'label': 'Business', 'icon': 'business'},
      {'key': 'gift', 'label': 'Gift', 'icon': 'card_giftcard'},
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sources.map((s) {
        final isSelected = _fundingSource == s['key'];
        return GestureDetector(
          onTap: () => setState(() => _fundingSource = s['key'] as String),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryContainer
                  : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isSelected ? AppTheme.primary : AppTheme.outlineLight,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: s['icon'] as String,
                  color: isSelected ? AppTheme.primary : AppTheme.mutedLight,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  s['label'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppTheme.primary : AppTheme.mutedLight,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOwnershipTypeRow(ThemeData theme) {
    final types = [
      {'key': 'individual', 'label': 'Individual', 'icon': 'person'},
      {'key': 'joint', 'label': 'Joint', 'icon': 'people'},
      {'key': 'business', 'label': 'Business', 'icon': 'business'},
      {
        'key': 'organization',
        'label': 'Organization',
        'icon': 'corporate_fare',
      },
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((t) {
        final isSelected = _ownershipType == t['key'];
        return GestureDetector(
          onTap: () => setState(() => _ownershipType = t['key'] as String),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryContainer
                  : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isSelected ? AppTheme.primary : AppTheme.outlineLight,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: t['icon'] as String,
                  color: isSelected ? AppTheme.primary : AppTheme.mutedLight,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  t['label'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppTheme.primary : AppTheme.mutedLight,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar(ThemeData theme, List<String> steps) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
                  side: const BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Back',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
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
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _currentStep < 3
                          ? 'Continue'
                          : (_isEditing ? 'Update Asset' : 'Save Asset'),
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.onSurfaceLight,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String icon;
  final TextInputType keyboardType;
  final int maxLines;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: AppTheme.onSurfaceLight,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: CustomIconWidget(
            iconName: icon,
            color: AppTheme.primary,
            size: 18,
          ),
        ),
        filled: true,
        fillColor: AppTheme.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.outlineLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.outlineLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: AppTheme.mutedLight,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReviewRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.mutedLight,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceLight,
            ),
          ),
        ],
      ),
    );
  }
}
