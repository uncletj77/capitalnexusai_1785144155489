import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/master_asset_registry_service.dart';
import '../../services/supabase_service.dart';

class AddInvestmentScreen extends StatefulWidget {
  final Map<String, dynamic>? existingInvestment;
  const AddInvestmentScreen({super.key, this.existingInvestment});

  @override
  State<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  final _client = SupabaseService.client;
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isSaving = false;

  // Step 1 – Basic Info
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedCategory = 'real_estate';
  String _selectedPortfolioId = '';
  List<Map<String, dynamic>> _portfolios = [];

  // Step 2 – Financial
  final _initialValueCtrl = TextEditingController();
  final _currentValueCtrl = TextEditingController();
  final _ownershipCtrl = TextEditingController(text: '100');
  final _expectedReturnCtrl = TextEditingController();
  String _riskLevel = 'medium';

  // Step 3 – Time & Location
  DateTime _investmentDate = DateTime.now();
  DateTime? _exitDate;
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final Map<String, String> _categoryLabels = {
    'real_estate': 'Real Estate',
    'business': 'Business',
    'stocks': 'Stocks & Bonds',
    'agriculture': 'Agriculture',
    'digital': 'Digital Assets',
    'other': 'Other',
  };

  final Map<String, IconData> _categoryIcons = {
    'real_estate': Icons.home_work,
    'business': Icons.business_center,
    'stocks': Icons.show_chart,
    'agriculture': Icons.grass,
    'digital': Icons.currency_bitcoin,
    'other': Icons.category,
  };

  @override
  void initState() {
    super.initState();
    _loadPortfolios();
    if (widget.existingInvestment != null) {
      _prefill(widget.existingInvestment!);
    }
  }

  void _prefill(Map<String, dynamic> inv) {
    _nameCtrl.text = inv['name'] ?? '';
    _descCtrl.text = inv['description'] ?? '';
    _selectedCategory = inv['category'] ?? 'real_estate';
    _selectedPortfolioId = inv['portfolio_id'] ?? '';
    _initialValueCtrl.text =
        (inv['initial_value'] as num?)?.toStringAsFixed(0) ?? '';
    _currentValueCtrl.text =
        (inv['current_value'] as num?)?.toStringAsFixed(0) ?? '';
    _ownershipCtrl.text =
        (inv['ownership_percentage'] as num?)?.toStringAsFixed(0) ?? '100';
    _expectedReturnCtrl.text =
        (inv['expected_return_rate'] as num?)?.toStringAsFixed(1) ?? '';
    _riskLevel = inv['risk_level'] ?? 'medium';
    _locationCtrl.text = inv['location'] ?? '';
    _notesCtrl.text = inv['notes'] ?? '';
    if (inv['investment_date'] != null) {
      _investmentDate =
          DateTime.tryParse(inv['investment_date']) ?? DateTime.now();
    }
    if (inv['target_exit_date'] != null) {
      _exitDate = DateTime.tryParse(inv['target_exit_date']);
    }
  }

  Future<void> _loadPortfolios() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      final res = await _client
          .from('investment_portfolios')
          .select()
          .eq('owner_id', userId)
          .eq('is_active', true);
      setState(() {
        _portfolios = List<Map<String, dynamic>>.from(res);
        if (_portfolios.isNotEmpty && _selectedPortfolioId.isEmpty) {
          _selectedPortfolioId = _portfolios.first['id'] as String;
        }
      });
    } catch (_) {}
  }

  Future<void> _createPortfolio(String name) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      final res = await _client
          .from('investment_portfolios')
          .insert({'owner_id': userId, 'name': name, 'purpose': 'general'})
          .select()
          .single();
      setState(() {
        _portfolios.add(res);
        _selectedPortfolioId = res['id'] as String;
      });
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _selectedPortfolioId.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final data = {
        'portfolio_id': _selectedPortfolioId,
        'owner_id': userId,
        'name': _nameCtrl.text.trim(),
        'category': _selectedCategory,
        'description': _descCtrl.text.trim(),
        'initial_value': double.tryParse(_initialValueCtrl.text) ?? 0,
        'current_value':
            double.tryParse(_currentValueCtrl.text) ??
            double.tryParse(_initialValueCtrl.text) ??
            0,
        'ownership_percentage': double.tryParse(_ownershipCtrl.text) ?? 100,
        'expected_return_rate': double.tryParse(_expectedReturnCtrl.text) ?? 0,
        'risk_level': _riskLevel,
        'investment_date': _investmentDate.toIso8601String().split('T')[0],
        'target_exit_date': _exitDate?.toIso8601String().split('T')[0],
        'location': _locationCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
        'status': 'active',
        'is_active': true,
      };

      if (widget.existingInvestment != null) {
        await _client
            .from('investments')
            .update(data)
            .eq('id', widget.existingInvestment!['id'] as String);
      } else {
        final inv = await _client
            .from('investments')
            .insert(data)
            .select()
            .single();
        // Record initial contribution transaction
        await _client.from('investment_transactions').insert({
          'investment_id': inv['id'],
          'owner_id': userId,
          'type': 'contribution',
          'amount': double.tryParse(_initialValueCtrl.text) ?? 0,
          'description': 'Initial investment',
          'transaction_date': _investmentDate.toIso8601String().split('T')[0],
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingInvestment != null
                  ? 'Investment updated!'
                  : 'Investment added!',
            ),
            backgroundColor: const Color(0xFF27AE60),
          ),
        );
        // Auto-register in Asset Intelligence
        await MasterAssetRegistryService.instance.autoRegisterAllAssets();
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existingInvestment != null;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEdit ? 'Edit Investment' : 'Add Investment',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_currentStep == 2)
            TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Save',
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF1A5F7A),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildStepIndicator(theme),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(theme),
                _buildStep2(theme),
                _buildStep3(theme),
              ],
            ),
          ),
          _buildNavButtons(theme),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme) {
    final steps = ['Basic Info', 'Financials', 'Details'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: steps.asMap().entries.map((e) {
          final isActive = e.key == _currentStep;
          final isDone = e.key < _currentStep;
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
                              ? const Color(0xFF1A5F7A)
                              : theme.colorScheme.outline.withAlpha(60),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.value,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isActive
                              ? const Color(0xFF1A5F7A)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (e.key < steps.length - 1) const SizedBox(width: 4),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStep1(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(theme, 'Investment Name'),
          _textField(theme, _nameCtrl, 'e.g. Mikocheni Land Plot'),
          const SizedBox(height: 16),
          _sectionLabel(theme, 'Description'),
          _textField(theme, _descCtrl, 'Brief description...', maxLines: 3),
          const SizedBox(height: 16),
          _sectionLabel(theme, 'Category'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categoryLabels.entries.map((e) {
              final isSelected = _selectedCategory == e.key;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1A5F7A)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1A5F7A)
                          : theme.colorScheme.outline.withAlpha(60),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _categoryIcons[e.key] ?? Icons.category,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        e.value,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _sectionLabel(theme, 'Portfolio'),
          const SizedBox(height: 8),
          if (_portfolios.isEmpty)
            GestureDetector(
              onTap: () async {
                final ctrl = TextEditingController();
                await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(
                      'New Portfolio',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                    ),
                    content: TextField(
                      controller: ctrl,
                      decoration: const InputDecoration(
                        hintText: 'Portfolio name',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (ctrl.text.isNotEmpty) {
                            _createPortfolio(ctrl.text.trim());
                          }
                        },
                        child: const Text('Create'),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A5F7A).withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF1A5F7A).withAlpha(60),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add, color: Color(0xFF1A5F7A), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Create a portfolio first',
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF1A5F7A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _selectedPortfolioId.isNotEmpty
                  ? _selectedPortfolioId
                  : null,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withAlpha(60),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              items: _portfolios.map((p) {
                return DropdownMenuItem<String>(
                  value: p['id'] as String,
                  child: Text(
                    p['name'] as String,
                    style: GoogleFonts.manrope(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedPortfolioId = v ?? ''),
            ),
        ],
      ),
    );
  }

  Widget _buildStep2(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(theme, 'Initial Capital (TSh)'),
          _textField(
            theme,
            _initialValueCtrl,
            'e.g. 50000000',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _sectionLabel(theme, 'Current Value (TSh)'),
          _textField(
            theme,
            _currentValueCtrl,
            'e.g. 65000000',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _sectionLabel(theme, 'Ownership Percentage (%)'),
          _textField(
            theme,
            _ownershipCtrl,
            'e.g. 100',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _sectionLabel(theme, 'Expected Annual Return (%)'),
          _textField(
            theme,
            _expectedReturnCtrl,
            'e.g. 15',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _sectionLabel(theme, 'Risk Level'),
          const SizedBox(height: 8),
          Row(
            children: ['low', 'medium', 'high', 'very_high'].map((r) {
              final isSelected = _riskLevel == r;
              final labels = {
                'low': 'Low',
                'medium': 'Medium',
                'high': 'High',
                'very_high': 'Very High',
              };
              final colors = {
                'low': const Color(0xFF27AE60),
                'medium': const Color(0xFFF2994A),
                'high': const Color(0xFFEB5757),
                'very_high': const Color(0xFF9B51E0),
              };
              final color = colors[r]!;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _riskLevel = r),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withAlpha(30)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : theme.colorScheme.outline.withAlpha(40),
                      ),
                    ),
                    child: Text(
                      labels[r]!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? color
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          if (_initialValueCtrl.text.isNotEmpty &&
              _currentValueCtrl.text.isNotEmpty)
            _buildRoiPreview(theme),
        ],
      ),
    );
  }

  Widget _buildRoiPreview(ThemeData theme) {
    final initial = double.tryParse(_initialValueCtrl.text) ?? 0;
    final current = double.tryParse(_currentValueCtrl.text) ?? 0;
    final profit = current - initial;
    final roi = initial > 0 ? (profit / initial) * 100 : 0.0;
    final isPositive = profit >= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPositive
            ? const Color(0xFF27AE60).withAlpha(15)
            : const Color(0xFFEB5757).withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPositive
              ? const Color(0xFF27AE60).withAlpha(60)
              : const Color(0xFFEB5757).withAlpha(60),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _roiStat(
            theme,
            'Profit/Loss',
            'TSh ${profit.abs().toStringAsFixed(0)}',
            isPositive ? const Color(0xFF27AE60) : const Color(0xFFEB5757),
          ),
          _roiStat(
            theme,
            'ROI',
            '${roi.toStringAsFixed(1)}%',
            isPositive ? const Color(0xFF27AE60) : const Color(0xFFEB5757),
          ),
        ],
      ),
    );
  }

  Widget _roiStat(ThemeData theme, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStep3(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(theme, 'Investment Date'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _investmentDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _investmentDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outline.withAlpha(60),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    '${_investmentDate.day}/${_investmentDate.month}/${_investmentDate.year}',
                    style: GoogleFonts.manrope(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _sectionLabel(theme, 'Target Exit Date (Optional)'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate:
                    _exitDate ?? DateTime.now().add(const Duration(days: 365)),
                firstDate: DateTime.now(),
                lastDate: DateTime(2050),
              );
              if (picked != null) setState(() => _exitDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outline.withAlpha(60),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    _exitDate != null
                        ? '${_exitDate!.day}/${_exitDate!.month}/${_exitDate!.year}'
                        : 'No exit date set',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: _exitDate != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (_exitDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _exitDate = null),
                      child: const Icon(Icons.clear, size: 18),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _sectionLabel(theme, 'Location'),
          _textField(theme, _locationCtrl, 'e.g. Dar es Salaam'),
          const SizedBox(height: 16),
          _sectionLabel(theme, 'Notes'),
          _textField(theme, _notesCtrl, 'Additional notes...', maxLines: 4),
        ],
      ),
    );
  }

  Widget _buildNavButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withAlpha(40)),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _currentStep--);
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Back',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      if (_currentStep < 2) {
                        setState(() => _currentStep++);
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      } else {
                        _save();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A5F7A),
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
                      _currentStep < 2 ? 'Continue' : 'Save Investment',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme, String label) {
    return Text(
      label,
      style: GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _textField(
    ThemeData theme,
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.manrope(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withAlpha(60),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withAlpha(60),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _initialValueCtrl.dispose();
    _currentValueCtrl.dispose();
    _ownershipCtrl.dispose();
    _expectedReturnCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }
}
