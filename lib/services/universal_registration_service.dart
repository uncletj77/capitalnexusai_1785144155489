import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './finance_service.dart';
import './enterprise_sync_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UNIVERSAL REGISTRATION ENGINE (URE) + TRANSACTION INTELLIGENCE ENGINE (TIE)
//
// Single authoritative entry point for ALL financial records in CNA.
// Every financial event is: entered once, validated once, stored once,
// assigned one permanent ID, linked to every related module, and
// automatically synchronized throughout the entire Wealth Operating System.
// ─────────────────────────────────────────────────────────────────────────────

// ─── ENUMS & CONSTANTS ───────────────────────────────────────────────────────

enum RegistrationCategory {
  transaction,
  business,
  investment,
  asset,
  loan,
  organization,
}

enum OwnershipType {
  personal,
  business,
  organization,
  investment,
  joint,
  other,
}

enum TiePipelineStage {
  initiation,
  ownershipIdentification,
  sourceSelection,
  destinationIdentification,
  financialClassification,
  validation,
  preview,
  commit,
  synchronization,
}

class RegistrationCategory_ {
  static const Map<RegistrationCategory, String> labels = {
    RegistrationCategory.transaction: 'Financial Transaction',
    RegistrationCategory.business: 'Business Record',
    RegistrationCategory.investment: 'Investment Record',
    RegistrationCategory.asset: 'Asset Record',
    RegistrationCategory.loan: 'Loan Record',
    RegistrationCategory.organization: 'Organization Record',
  };

  static const Map<RegistrationCategory, String> icons = {
    RegistrationCategory.transaction: 'swap_horiz',
    RegistrationCategory.business: 'business_center',
    RegistrationCategory.investment: 'trending_up',
    RegistrationCategory.asset: 'real_estate_agent',
    RegistrationCategory.loan: 'account_balance',
    RegistrationCategory.organization: 'corporate_fare',
  };
}

// ─── REGISTRATION TYPES ──────────────────────────────────────────────────────

class RegistrationTypes {
  static const Map<RegistrationCategory, List<Map<String, String>>>
  byCategory = {
    RegistrationCategory.transaction: [
      {
        'key': 'income',
        'label': 'Income',
        'icon': 'add_circle',
        'color': '0xFF10B981',
      },
      {
        'key': 'expense',
        'label': 'Expense',
        'icon': 'remove_circle',
        'color': '0xFFEF4444',
      },
      {
        'key': 'transfer',
        'label': 'Transfer',
        'icon': 'swap_horiz',
        'color': '0xFF2D9CDB',
      },
      {
        'key': 'refund',
        'label': 'Refund',
        'icon': 'undo',
        'color': '0xFF8B5CF6',
      },
      {
        'key': 'adjustment',
        'label': 'Adjustment',
        'icon': 'tune',
        'color': '0xFFF59E0B',
      },
      {
        'key': 'salary',
        'label': 'Salary',
        'icon': 'payments',
        'color': '0xFF059669',
      },
      {
        'key': 'commission',
        'label': 'Commission',
        'icon': 'percent',
        'color': '0xFF0EA5E9',
      },
      {'key': 'bonus', 'label': 'Bonus', 'icon': 'star', 'color': '0xFFD97706'},
      {
        'key': 'dividend',
        'label': 'Dividend',
        'icon': 'account_balance_wallet',
        'color': '0xFF10B981',
      },
      {
        'key': 'interest',
        'label': 'Interest',
        'icon': 'calculate',
        'color': '0xFF6366F1',
      },
      {
        'key': 'fees',
        'label': 'Fees',
        'icon': 'receipt',
        'color': '0xFFEF4444',
      },
      {'key': 'tax', 'label': 'Tax', 'icon': 'gavel', 'color': '0xFFB91C1C'},
      {
        'key': 'donation',
        'label': 'Donation',
        'icon': 'volunteer_activism',
        'color': '0xFFEC4899',
      },
      {
        'key': 'other',
        'label': 'Other',
        'icon': 'more_horiz',
        'color': '0xFF64748B',
      },
    ],
    RegistrationCategory.business: [
      {
        'key': 'business_registration',
        'label': 'New Business',
        'icon': 'add_business',
        'color': '0xFF059669',
      },
      {
        'key': 'business_income',
        'label': 'Business Income',
        'icon': 'trending_up',
        'color': '0xFF10B981',
      },
      {
        'key': 'business_expense',
        'label': 'Business Expense',
        'icon': 'trending_down',
        'color': '0xFFEF4444',
      },
      {
        'key': 'business_asset',
        'label': 'Business Asset',
        'icon': 'real_estate_agent',
        'color': '0xFF2D9CDB',
      },
      {
        'key': 'business_liability',
        'label': 'Business Liability',
        'icon': 'account_balance',
        'color': '0xFFB91C1C',
      },
      {
        'key': 'inventory_purchase',
        'label': 'Inventory Purchase',
        'icon': 'inventory',
        'color': '0xFF8B5CF6',
      },
      {
        'key': 'inventory_sale',
        'label': 'Inventory Sale',
        'icon': 'sell',
        'color': '0xFF10B981',
      },
      {
        'key': 'capital_injection',
        'label': 'Capital Injection',
        'icon': 'add_card',
        'color': '0xFF059669',
      },
      {
        'key': 'owner_drawings',
        'label': 'Owner Drawings',
        'icon': 'money_off',
        'color': '0xFFF59E0B',
      },
    ],
    RegistrationCategory.investment: [
      {
        'key': 'new_investment',
        'label': 'New Investment',
        'icon': 'add_chart',
        'color': '0xFF2D9CDB',
      },
      {
        'key': 'additional_investment',
        'label': 'Additional Investment',
        'icon': 'add_circle',
        'color': '0xFF10B981',
      },
      {
        'key': 'investment_withdrawal',
        'label': 'Withdrawal',
        'icon': 'remove_circle',
        'color': '0xFFEF4444',
      },
      {
        'key': 'investment_return',
        'label': 'Investment Return',
        'icon': 'trending_up',
        'color': '0xFF059669',
      },
      {
        'key': 'investment_dividend',
        'label': 'Investment Dividend',
        'icon': 'payments',
        'color': '0xFF10B981',
      },
      {
        'key': 'investment_valuation',
        'label': 'Valuation Update',
        'icon': 'price_change',
        'color': '0xFF8B5CF6',
      },
    ],
    RegistrationCategory.asset: [
      {
        'key': 'fixed_asset',
        'label': 'Fixed Asset',
        'icon': 'home_work',
        'color': '0xFF8B5CF6',
      },
      {
        'key': 'current_asset',
        'label': 'Current Asset',
        'icon': 'account_balance_wallet',
        'color': '0xFF0EA5E9',
      },
      {
        'key': 'financial_asset',
        'label': 'Financial Asset',
        'icon': 'show_chart',
        'color': '0xFF10B981',
      },
      {
        'key': 'digital_asset',
        'label': 'Digital Asset',
        'icon': 'currency_bitcoin',
        'color': '0xFFF59E0B',
      },
      {
        'key': 'business_asset',
        'label': 'Business Asset',
        'icon': 'business_center',
        'color': '0xFF059669',
      },
      {
        'key': 'personal_asset',
        'label': 'Personal Asset',
        'icon': 'person',
        'color': '0xFF2D9CDB',
      },
    ],
    RegistrationCategory.loan: [
      {
        'key': 'loan_receivable',
        'label': 'Loan Receivable',
        'icon': 'arrow_upward',
        'color': '0xFF10B981',
      },
      {
        'key': 'loan_payable',
        'label': 'Loan Payable',
        'icon': 'arrow_downward',
        'color': '0xFFEF4444',
      },
      {
        'key': 'loan_repayment',
        'label': 'Loan Repayment',
        'icon': 'payments',
        'color': '0xFF2D9CDB',
      },
      {
        'key': 'partial_repayment',
        'label': 'Partial Repayment',
        'icon': 'percent',
        'color': '0xFF8B5CF6',
      },
      {
        'key': 'interest_payment',
        'label': 'Interest Payment',
        'icon': 'calculate',
        'color': '0xFFF59E0B',
      },
      {
        'key': 'loan_extension',
        'label': 'Loan Extension',
        'icon': 'schedule',
        'color': '0xFF64748B',
      },
      {
        'key': 'loan_settlement',
        'label': 'Loan Settlement',
        'icon': 'check_circle',
        'color': '0xFF059669',
      },
    ],
    RegistrationCategory.organization: [
      {
        'key': 'organization_registration',
        'label': 'New Organization',
        'icon': 'corporate_fare',
        'color': '0xFF1A5F7A',
      },
      {
        'key': 'department',
        'label': 'Department',
        'icon': 'account_tree',
        'color': '0xFF2D9CDB',
      },
      {
        'key': 'branch',
        'label': 'Branch',
        'icon': 'store',
        'color': '0xFF059669',
      },
      {
        'key': 'project',
        'label': 'Project',
        'icon': 'folder_special',
        'color': '0xFF8B5CF6',
      },
      {'key': 'team', 'label': 'Team', 'icon': 'group', 'color': '0xFFF59E0B'},
    ],
  };
}

// ─── FIELD DEFINITIONS ───────────────────────────────────────────────────────

class RegistrationField {
  final String key;
  final String label;
  final String
  type; // 'text', 'number', 'date', 'select', 'lookup', 'textarea', 'currency', 'toggle'
  final bool required;
  final String? hint;
  final List<Map<String, String>>? options;
  final String? lookupTable; // for 'lookup' type
  final String? defaultValue;

  const RegistrationField({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.hint,
    this.options,
    this.lookupTable,
    this.defaultValue,
  });
}

class RegistrationFormSchema {
  static List<RegistrationField> getFields(String registrationType) {
    switch (registrationType) {
      case 'income':
      case 'expense':
      case 'salary':
      case 'commission':
      case 'bonus':
      case 'dividend':
      case 'interest':
      case 'fees':
      case 'tax':
      case 'donation':
      case 'refund':
      case 'adjustment':
      case 'other':
        return _transactionFields(registrationType);
      case 'transfer':
        return _transferFields();
      case 'business_income':
      case 'business_expense':
        return _businessTransactionFields(registrationType);
      case 'business_registration':
        return _businessRegistrationFields();
      case 'new_investment':
      case 'additional_investment':
        return _investmentFields();
      case 'investment_withdrawal':
      case 'investment_return':
      case 'investment_dividend':
        return _investmentTransactionFields(registrationType);
      case 'investment_valuation':
        return _investmentValuationFields();
      case 'fixed_asset':
      case 'current_asset':
      case 'financial_asset':
      case 'digital_asset':
      case 'business_asset':
      case 'personal_asset':
        return _assetFields(registrationType);
      case 'loan_receivable':
        return _loanReceivableFields();
      case 'loan_payable':
        return _loanPayableFields();
      case 'loan_repayment':
      case 'partial_repayment':
      case 'interest_payment':
        return _loanRepaymentFields(registrationType);
      case 'loan_settlement':
        return _loanSettlementFields();
      case 'organization_registration':
        return _organizationFields();
      default:
        return _genericFields();
    }
  }

  static List<RegistrationField> _transactionFields(String type) => [
    const RegistrationField(
      key: 'description',
      label: 'Description',
      type: 'text',
      required: true,
      hint: 'What is this transaction for?',
    ),
    const RegistrationField(
      key: 'amount',
      label: 'Amount',
      type: 'currency',
      required: true,
    ),
    const RegistrationField(
      key: 'transaction_date',
      label: 'Date',
      type: 'date',
      required: true,
    ),
    const RegistrationField(
      key: 'account_id',
      label: 'Account',
      type: 'lookup',
      required: true,
      lookupTable: 'financial_accounts',
      hint: 'Which account?',
    ),
    const RegistrationField(
      key: 'category',
      label: 'Category',
      type: 'select',
      required: true,
      options: [
        {'key': 'salary', 'label': 'Salary'},
        {'key': 'business', 'label': 'Business'},
        {'key': 'investment', 'label': 'Investment'},
        {'key': 'rental', 'label': 'Rental'},
        {'key': 'freelance', 'label': 'Freelance'},
        {'key': 'food', 'label': 'Food & Dining'},
        {'key': 'transport', 'label': 'Transport'},
        {'key': 'utilities', 'label': 'Utilities'},
        {'key': 'healthcare', 'label': 'Healthcare'},
        {'key': 'education', 'label': 'Education'},
        {'key': 'entertainment', 'label': 'Entertainment'},
        {'key': 'shopping', 'label': 'Shopping'},
        {'key': 'other', 'label': 'Other'},
      ],
    ),
    const RegistrationField(
      key: 'related_business_id',
      label: 'Linked Business',
      type: 'lookup',
      lookupTable: 'businesses',
      hint: 'Optional: link to a business',
    ),
    const RegistrationField(
      key: 'related_goal_id',
      label: 'Linked Goal',
      type: 'lookup',
      lookupTable: 'financial_goals',
      hint: 'Optional: link to a goal',
    ),
    const RegistrationField(
      key: 'notes',
      label: 'Notes',
      type: 'textarea',
      hint: 'Additional details',
    ),
  ];

  static List<RegistrationField> _transferFields() => [
    const RegistrationField(
      key: 'description',
      label: 'Description',
      type: 'text',
      required: true,
      hint: 'Transfer description',
    ),
    const RegistrationField(
      key: 'amount',
      label: 'Amount',
      type: 'currency',
      required: true,
    ),
    const RegistrationField(
      key: 'transaction_date',
      label: 'Date',
      type: 'date',
      required: true,
    ),
    const RegistrationField(
      key: 'account_id',
      label: 'From Account',
      type: 'lookup',
      required: true,
      lookupTable: 'financial_accounts',
    ),
    const RegistrationField(
      key: 'destination_account_id',
      label: 'To Account',
      type: 'lookup',
      required: true,
      lookupTable: 'financial_accounts',
    ),
    const RegistrationField(key: 'notes', label: 'Notes', type: 'textarea'),
  ];

  static List<RegistrationField> _businessTransactionFields(String type) => [
    const RegistrationField(
      key: 'related_business_id',
      label: 'Business',
      type: 'lookup',
      required: true,
      lookupTable: 'businesses',
    ),
    const RegistrationField(
      key: 'description',
      label: 'Description',
      type: 'text',
      required: true,
    ),
    const RegistrationField(
      key: 'amount',
      label: 'Amount',
      type: 'currency',
      required: true,
    ),
    const RegistrationField(
      key: 'transaction_date',
      label: 'Date',
      type: 'date',
      required: true,
    ),
    const RegistrationField(
      key: 'account_id',
      label: 'Account',
      type: 'lookup',
      required: true,
      lookupTable: 'financial_accounts',
    ),
    const RegistrationField(
      key: 'category',
      label: 'Category',
      type: 'select',
      required: true,
      options: [
        {'key': 'revenue', 'label': 'Revenue'},
        {'key': 'cost_of_goods', 'label': 'Cost of Goods'},
        {'key': 'operating_expense', 'label': 'Operating Expense'},
        {'key': 'payroll', 'label': 'Payroll'},
        {'key': 'marketing', 'label': 'Marketing'},
        {'key': 'rent', 'label': 'Rent'},
        {'key': 'utilities', 'label': 'Utilities'},
        {'key': 'other', 'label': 'Other'},
      ],
    ),
    const RegistrationField(
      key: 'vendor_customer',
      label: 'Vendor / Customer',
      type: 'text',
      hint: 'Who is this with?',
    ),
    const RegistrationField(key: 'notes', label: 'Notes', type: 'textarea'),
  ];

  static List<RegistrationField> _businessRegistrationFields() => [
    const RegistrationField(
      key: 'name',
      label: 'Business Name',
      type: 'text',
      required: true,
    ),
    const RegistrationField(
      key: 'business_type',
      label: 'Business Type',
      type: 'select',
      required: true,
      options: [
        {'key': 'sole_proprietorship', 'label': 'Sole Proprietorship'},
        {'key': 'partnership', 'label': 'Partnership'},
        {'key': 'limited_company', 'label': 'Limited Company'},
        {'key': 'corporation', 'label': 'Corporation'},
        {'key': 'ngo', 'label': 'NGO / Non-Profit'},
        {'key': 'other', 'label': 'Other'},
      ],
    ),
    const RegistrationField(
      key: 'industry',
      label: 'Industry',
      type: 'text',
      required: true,
    ),
    const RegistrationField(
      key: 'registration_number',
      label: 'Registration Number',
      type: 'text',
    ),
    const RegistrationField(
      key: 'start_date',
      label: 'Start Date',
      type: 'date',
    ),
    const RegistrationField(
      key: 'description',
      label: 'Description',
      type: 'textarea',
    ),
  ];

  static List<RegistrationField> _investmentFields() => [
    const RegistrationField(
      key: 'name',
      label: 'Investment Name',
      type: 'text',
      required: true,
    ),
    const RegistrationField(
      key: 'category',
      label: 'Investment Type',
      type: 'select',
      required: true,
      options: [
        {'key': 'real_estate', 'label': 'Real Estate'},
        {'key': 'business', 'label': 'Business'},
        {'key': 'stocks', 'label': 'Stocks & Bonds'},
        {'key': 'agriculture', 'label': 'Agriculture'},
        {'key': 'digital', 'label': 'Digital Assets'},
        {'key': 'other', 'label': 'Other'},
      ],
    ),
    const RegistrationField(
      key: 'initial_value',
      label: 'Capital Invested',
      type: 'currency',
      required: true,
    ),
    const RegistrationField(
      key: 'current_value',
      label: 'Current Value',
      type: 'currency',
      required: true,
    ),
    const RegistrationField(
      key: 'expected_return_rate',
      label: 'Expected Return (%)',
      type: 'number',
    ),
    const RegistrationField(
      key: 'risk_level',
      label: 'Risk Level',
      type: 'select',
      options: [
        {'key': 'low', 'label': 'Low'},
        {'key': 'medium', 'label': 'Medium'},
        {'key': 'high', 'label': 'High'},
      ],
      defaultValue: 'medium',
    ),
    const RegistrationField(
      key: 'account_id',
      label: 'Linked Account',
      type: 'lookup',
      lookupTable: 'financial_accounts',
    ),
    const RegistrationField(
      key: 'investment_date',
      label: 'Investment Date',
      type: 'date',
      required: true,
    ),
    const RegistrationField(
      key: 'description',
      label: 'Notes',
      type: 'textarea',
    ),
  ];

  static List<RegistrationField> _investmentTransactionFields(String type) => [
    const RegistrationField(
      key: 'investment_id',
      label: 'Investment',
      type: 'lookup',
      required: true,
      lookupTable: 'investments',
    ),
    const RegistrationField(
      key: 'amount',
      label: 'Amount',
      type: 'currency',
      required: true,
    ),
    const RegistrationField(
      key: 'transaction_date',
      label: 'Date',
      type: 'date',
      required: true,
    ),
    const RegistrationField(
      key: 'account_id',
      label: 'Account',
      type: 'lookup',
      lookupTable: 'financial_accounts',
    ),
    const RegistrationField(key: 'notes', label: 'Notes', type: 'textarea'),
  ];

  static List<RegistrationField> _investmentValuationFields() => [
    const RegistrationField(
      key: 'investment_id',
      label: 'Investment',
      type: 'lookup',
      required: true,
      lookupTable: 'investments',
    ),
    const RegistrationField(
      key: 'current_value',
      label: 'New Current Value',
      type: 'currency',
      required: true,
    ),
    const RegistrationField(
      key: 'valuation_date',
      label: 'Valuation Date',
      type: 'date',
      required: true,
    ),
    const RegistrationField(key: 'notes', label: 'Notes', type: 'textarea'),
  ];

  static List<RegistrationField> _assetFields(String type) => [
    const RegistrationField(
      key: 'asset_name',
      label: 'Asset Name',
      type: 'text',
      required: true,
    ),
    const RegistrationField(
      key: 'asset_type',
      label: 'Asset Type',
      type: 'select',
      required: true,
      options: [
        {'key': 'property', 'label': 'Property'},
        {'key': 'vehicle', 'label': 'Vehicle'},
        {'key': 'equipment', 'label': 'Equipment'},
        {'key': 'land', 'label': 'Land'},
        {'key': 'building', 'label': 'Building'},
        {'key': 'inventory', 'label': 'Inventory'},
        {'key': 'receivable', 'label': 'Receivable'},
        {'key': 'cash', 'label': 'Cash'},
        {'key': 'crypto', 'label': 'Cryptocurrency'},
        {'key': 'other', 'label': 'Other'},
      ],
    ),
    const RegistrationField(
      key: 'purchase_price',
      label: 'Purchase Price',
      type: 'currency',
      required: true,
    ),
    const RegistrationField(
      key: 'current_value',
      label: 'Current Value',
      type: 'currency',
      required: true,
    ),
    const RegistrationField(
      key: 'purchase_date',
      label: 'Purchase Date',
      type: 'date',
    ),
    const RegistrationField(
      key: 'related_business_id',
      label: 'Linked Business',
      type: 'lookup',
      lookupTable: 'businesses',
    ),
    const RegistrationField(
      key: 'description',
      label: 'Description',
      type: 'textarea',
    ),
    const RegistrationField(key: 'notes', label: 'Notes', type: 'textarea'),
  ];

  static List<RegistrationField> _loanReceivableFields() => [
    const RegistrationField(
      key: 'borrower_name',
      label: 'Borrower Name',
      type: 'text',
      required: true,
    ),
    const RegistrationField(
      key: 'borrower_phone',
      label: 'Borrower Phone',
      type: 'text',
    ),
    const RegistrationField(
      key: 'principal_amount',
      label: 'Loan Amount',
      type: 'currency',
      required: true,
    ),
    const RegistrationField(
      key: 'interest_rate',
      label: 'Interest Rate (%)',
      type: 'number',
    ),
    const RegistrationField(
      key: 'interest_type',
      label: 'Interest Type',
      type: 'select',
      options: [
        {'key': 'simple', 'label': 'Simple'},
        {'key': 'compound', 'label': 'Compound'},
        {'key': 'flat', 'label': 'Flat'},
      ],
      defaultValue: 'simple',
    ),
    const RegistrationField(
      key: 'issue_date',
      label: 'Issue Date',
      type: 'date',
      required: true,
    ),
    const RegistrationField(
      key: 'due_date',
      label: 'Due Date',
      type: 'date',
      required: true,
    ),
    const RegistrationField(
      key: 'account_id',
      label: 'Disbursed From Account',
      type: 'lookup',
      lookupTable: 'financial_accounts',
    ),
    const RegistrationField(
      key: 'collateral',
      label: 'Collateral',
      type: 'text',
    ),
    const RegistrationField(key: 'notes', label: 'Notes', type: 'textarea'),
  ];

  static List<RegistrationField> _loanPayableFields() => [
    const RegistrationField(
      key: 'lender_name',
      label: 'Lender Name',
      type: 'text',
      required: true,
    ),
    const RegistrationField(
      key: 'principal_amount',
      label: 'Loan Amount',
      type: 'currency',
      required: true,
    ),
    const RegistrationField(
      key: 'interest_rate',
      label: 'Interest Rate (%)',
      type: 'number',
    ),
    const RegistrationField(
      key: 'interest_type',
      label: 'Interest Type',
      type: 'select',
      options: [
        {'key': 'simple', 'label': 'Simple'},
        {'key': 'compound', 'label': 'Compound'},
        {'key': 'flat', 'label': 'Flat'},
      ],
      defaultValue: 'simple',
    ),
    const RegistrationField(
      key: 'issue_date',
      label: 'Issue Date',
      type: 'date',
      required: true,
    ),
    const RegistrationField(
      key: 'due_date',
      label: 'Due Date',
      type: 'date',
      required: true,
    ),
    const RegistrationField(
      key: 'account_id',
      label: 'Received Into Account',
      type: 'lookup',
      lookupTable: 'financial_accounts',
    ),
    const RegistrationField(
      key: 'purpose',
      label: 'Loan Purpose',
      type: 'text',
    ),
    const RegistrationField(key: 'notes', label: 'Notes', type: 'textarea'),
  ];

  static List<RegistrationField> _loanRepaymentFields(String type) => [
    const RegistrationField(
      key: 'loan_id',
      label: 'Loan',
      type: 'lookup',
      required: true,
      lookupTable: 'loans',
    ),
    const RegistrationField(
      key: 'amount',
      label: 'Repayment Amount',
      type: 'currency',
      required: true,
    ),
    const RegistrationField(
      key: 'payment_date',
      label: 'Payment Date',
      type: 'date',
      required: true,
    ),
    const RegistrationField(
      key: 'account_id',
      label: 'Paid From Account',
      type: 'lookup',
      lookupTable: 'financial_accounts',
    ),
    const RegistrationField(key: 'notes', label: 'Notes', type: 'textarea'),
  ];

  static List<RegistrationField> _loanSettlementFields() => [
    const RegistrationField(
      key: 'loan_id',
      label: 'Loan',
      type: 'lookup',
      required: true,
      lookupTable: 'loans',
    ),
    const RegistrationField(
      key: 'settlement_amount',
      label: 'Settlement Amount',
      type: 'currency',
      required: true,
    ),
    const RegistrationField(
      key: 'settlement_date',
      label: 'Settlement Date',
      type: 'date',
      required: true,
    ),
    const RegistrationField(
      key: 'account_id',
      label: 'Account Used',
      type: 'lookup',
      lookupTable: 'financial_accounts',
    ),
    const RegistrationField(key: 'notes', label: 'Notes', type: 'textarea'),
  ];

  static List<RegistrationField> _organizationFields() => [
    const RegistrationField(
      key: 'name',
      label: 'Organization Name',
      type: 'text',
      required: true,
    ),
    const RegistrationField(
      key: 'org_type',
      label: 'Type',
      type: 'select',
      required: true,
      options: [
        {'key': 'company', 'label': 'Company'},
        {'key': 'ngo', 'label': 'NGO'},
        {'key': 'government', 'label': 'Government'},
        {'key': 'cooperative', 'label': 'Cooperative'},
        {'key': 'other', 'label': 'Other'},
      ],
    ),
    const RegistrationField(
      key: 'description',
      label: 'Description',
      type: 'textarea',
    ),
    const RegistrationField(
      key: 'registration_number',
      label: 'Registration Number',
      type: 'text',
    ),
  ];

  static List<RegistrationField> _genericFields() => [
    const RegistrationField(
      key: 'description',
      label: 'Description',
      type: 'text',
      required: true,
    ),
    const RegistrationField(key: 'amount', label: 'Amount', type: 'currency'),
    const RegistrationField(
      key: 'date',
      label: 'Date',
      type: 'date',
      required: true,
    ),
    const RegistrationField(key: 'notes', label: 'Notes', type: 'textarea'),
  ];
}

// ─── VALIDATION RESULT ───────────────────────────────────────────────────────

class ValidationResult {
  final bool isValid;
  final Map<String, String> errors; // field key → error message
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    this.errors = const {},
    this.warnings = const [],
  });
}

// ─── COMMIT RESULT ───────────────────────────────────────────────────────────

class CommitResult {
  final bool success;
  final String? entityId;
  final String? entityTable;
  final String? errorMessage;
  final Map<String, bool> syncedModules;
  final Map<String, dynamic>? createdRecord;

  const CommitResult({
    required this.success,
    this.entityId,
    this.entityTable,
    this.errorMessage,
    this.syncedModules = const {},
    this.createdRecord,
  });
}

// ─── UNIVERSAL REGISTRATION SERVICE ─────────────────────────────────────────

class UniversalRegistrationService {
  static UniversalRegistrationService? _instance;
  static UniversalRegistrationService get instance =>
      _instance ??= UniversalRegistrationService._();
  UniversalRegistrationService._();

  SupabaseClient get _client => SupabaseService.client;
  String? get _userId => _client.auth.currentUser?.id;
  FinanceService get _finance => FinanceService.instance;

  // ─── DRAFT MANAGEMENT ──────────────────────────────────────────────────────

  String _draftKey(RegistrationCategory category, String type) =>
      '${category.name}_${type}_draft';

  Future<void> saveDraft({
    required RegistrationCategory category,
    required String registrationType,
    required int currentStep,
    required Map<String, dynamic> formData,
    required Map<String, dynamic> selectedRelationships,
  }) async {
    final userId = _userId;
    if (userId == null) return;
    final key = _draftKey(category, registrationType);
    try {
      await _client.from('registration_drafts').upsert({
        'user_id': userId,
        'draft_key': key,
        'registration_category': category.name,
        'registration_type': registrationType,
        'current_step': currentStep,
        'form_data': formData,
        'selected_relationships': selectedRelationships,
        'is_complete': false,
        'updated_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String(),
      }, onConflict: 'user_id,draft_key');
    } catch (e) {
      debugPrint('[URE] Draft save failed: $e');
    }
  }

  Future<Map<String, dynamic>?> loadDraft({
    required RegistrationCategory category,
    required String registrationType,
  }) async {
    final userId = _userId;
    if (userId == null) return null;
    final key = _draftKey(category, registrationType);
    try {
      final res = await _client
          .from('registration_drafts')
          .select()
          .eq('user_id', userId)
          .eq('draft_key', key)
          .eq('is_complete', false)
          .maybeSingle();
      return res;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getIncompleteDrafts() async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
        await _client
            .from('registration_drafts')
            .select()
            .eq('user_id', userId)
            .eq('is_complete', false)
            .gt('expires_at', DateTime.now().toIso8601String())
            .order('updated_at', ascending: false),
      );
    } catch (_) {
      return [];
    }
  }

  Future<void> markDraftComplete(
    RegistrationCategory category,
    String type,
  ) async {
    final userId = _userId;
    if (userId == null) return;
    final key = _draftKey(category, type);
    try {
      await _client
          .from('registration_drafts')
          .update({'is_complete': true})
          .eq('user_id', userId)
          .eq('draft_key', key);
    } catch (_) {}
  }

  Future<void> deleteDraft(RegistrationCategory category, String type) async {
    final userId = _userId;
    if (userId == null) return;
    final key = _draftKey(category, type);
    try {
      await _client
          .from('registration_drafts')
          .delete()
          .eq('user_id', userId)
          .eq('draft_key', key);
    } catch (_) {}
  }

  // ─── LOOKUP SERVICES ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> lookupEntities(String tableName) async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      switch (tableName) {
        case 'financial_accounts':
          return await _finance.getAccounts();
        case 'businesses':
          return List<Map<String, dynamic>>.from(
            await _client
                .from('businesses')
                .select('id, name, business_type, industry')
                .eq('owner_id', userId)
                .eq('is_active', true)
                .order('name'),
          );
        case 'investments':
          return List<Map<String, dynamic>>.from(
            await _client
                .from('investments')
                .select('id, name, category, current_value')
                .eq('user_id', userId)
                .order('name'),
          );
        case 'loans':
          return List<Map<String, dynamic>>.from(
            await _client
                .from('loans')
                .select(
                  'id, loan_name, principal_amount, outstanding_balance, loan_type',
                )
                .eq('user_id', userId)
                .neq('status', 'settled')
                .order('created_at', ascending: false),
          );
        case 'financial_goals':
          return List<Map<String, dynamic>>.from(
            await _client
                .from('financial_goals')
                .select('id, goal_name, target_amount, current_amount')
                .eq('user_id', userId)
                .eq('status', 'active')
                .order('goal_name'),
          );
        default:
          return [];
      }
    } catch (e) {
      debugPrint('[URE] Lookup failed for $tableName: $e');
      return [];
    }
  }

  String getEntityDisplayName(String tableName, Map<String, dynamic> entity) {
    switch (tableName) {
      case 'financial_accounts':
        return entity['account_name'] ?? entity['name'] ?? 'Unknown Account';
      case 'businesses':
        return entity['name'] ?? 'Unknown Business';
      case 'investments':
        return entity['name'] ?? 'Unknown Investment';
      case 'loans':
        return entity['loan_name'] ?? 'Unknown Loan';
      case 'financial_goals':
        return entity['goal_name'] ?? 'Unknown Goal';
      default:
        return entity['name'] ?? entity['title'] ?? 'Unknown';
    }
  }

  // ─── VALIDATION ENGINE ─────────────────────────────────────────────────────

  Future<ValidationResult> validate({
    required String registrationType,
    required Map<String, dynamic> formData,
    required Map<String, dynamic> relationships,
  }) async {
    final errors = <String, String>{};
    final warnings = <String>[];
    final fields = RegistrationFormSchema.getFields(registrationType);

    // 1. Required field check
    for (final field in fields) {
      if (field.required) {
        final val = formData[field.key];
        if (val == null || val.toString().trim().isEmpty) {
          errors[field.key] = '${field.label} is required';
        }
      }
    }

    // 2. Amount validation
    final amountKeys = [
      'amount',
      'principal_amount',
      'initial_value',
      'current_value',
      'purchase_price',
      'settlement_amount',
      'repayment_amount',
    ];
    for (final key in amountKeys) {
      if (formData.containsKey(key) && formData[key] != null) {
        final v = double.tryParse(formData[key].toString());
        if (v == null || v <= 0) {
          errors[key] = 'Amount must be greater than zero';
        }
      }
    }

    // 3. Date validation
    final dateKeys = [
      'transaction_date',
      'issue_date',
      'due_date',
      'purchase_date',
      'investment_date',
      'payment_date',
      'settlement_date',
      'valuation_date',
      'start_date',
    ];
    for (final key in dateKeys) {
      if (formData.containsKey(key) && formData[key] != null) {
        final d = DateTime.tryParse(formData[key].toString());
        if (d == null) {
          errors[key] = 'Invalid date format';
        }
      }
    }

    // 4. Due date must be after issue date for loans
    if (formData['issue_date'] != null && formData['due_date'] != null) {
      final issue = DateTime.tryParse(formData['issue_date'].toString());
      final due = DateTime.tryParse(formData['due_date'].toString());
      if (issue != null && due != null && due.isBefore(issue)) {
        errors['due_date'] = 'Due date must be after issue date';
      }
    }

    // 5. Transfer: source and destination must differ
    if (registrationType == 'transfer') {
      final src = formData['account_id'];
      final dst = formData['destination_account_id'];
      if (src != null && dst != null && src == dst) {
        errors['destination_account_id'] =
            'Source and destination accounts must be different';
      }
    }

    // 6. Interest rate range
    if (formData['interest_rate'] != null) {
      final rate = double.tryParse(formData['interest_rate'].toString());
      if (rate != null && (rate < 0 || rate > 100)) {
        errors['interest_rate'] = 'Interest rate must be between 0 and 100';
      }
    }

    // 7. Ownership percentage
    if (formData['ownership_percentage'] != null) {
      final pct = double.tryParse(formData['ownership_percentage'].toString());
      if (pct != null && (pct <= 0 || pct > 100)) {
        errors['ownership_percentage'] = 'Ownership must be between 1 and 100';
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  // ─── PREVIEW BUILDER ───────────────────────────────────────────────────────

  Map<String, dynamic> buildPreview({
    required RegistrationCategory category,
    required String registrationType,
    required Map<String, dynamic> formData,
    required Map<String, dynamic> relationships,
    required OwnershipType ownershipType,
  }) {
    final affectedModules = _getAffectedModules(category, registrationType);
    final financialImpact = _calculateFinancialImpact(
      category,
      registrationType,
      formData,
    );

    return {
      'registration_category': category.name,
      'registration_type': registrationType,
      'ownership_type': ownershipType.name,
      'form_data': formData,
      'relationships': relationships,
      'affected_modules': affectedModules,
      'financial_impact': financialImpact,
      'preview_generated_at': DateTime.now().toIso8601String(),
    };
  }

  List<String> _getAffectedModules(RegistrationCategory category, String type) {
    final base = ['Finance Engine', 'Dashboard', 'Recent Activity', 'Reports'];
    switch (category) {
      case RegistrationCategory.transaction:
        return [...base, 'Transaction History', 'Cash Flow', 'Net Worth'];
      case RegistrationCategory.business:
        return [...base, 'Business Dashboard', 'Business Ledger', 'Net Worth'];
      case RegistrationCategory.investment:
        return [
          ...base,
          'Investment Portfolio',
          'Asset Register',
          'Net Worth',
          'AI Brain',
        ];
      case RegistrationCategory.asset:
        return [...base, 'Asset Register', 'Net Worth', 'AI Brain'];
      case RegistrationCategory.loan:
        if (type == 'loan_receivable') {
          return [...base, 'Loan Receivables', 'Asset Register', 'Net Worth'];
        }
        return [...base, 'Loan Dashboard', 'Liabilities', 'Net Worth'];
      case RegistrationCategory.organization:
        return [...base, 'Organization Dashboard'];
    }
  }

  Map<String, String> _calculateFinancialImpact(
    RegistrationCategory category,
    String type,
    Map<String, dynamic> formData,
  ) {
    final impact = <String, String>{};
    final amountStr =
        (formData['amount'] ??
                formData['principal_amount'] ??
                formData['initial_value'] ??
                formData['purchase_price'] ??
                '0')
            .toString();
    final amount = double.tryParse(amountStr) ?? 0;

    if (amount > 0) {
      final formatted = _formatCurrency(amount);
      switch (type) {
        case 'income':
        case 'business_income':
        case 'investment_return':
        case 'investment_dividend':
          impact['Cash'] = '+$formatted';
          impact['Net Worth'] = '+$formatted';
          break;
        case 'expense':
        case 'business_expense':
          impact['Cash'] = '-$formatted';
          impact['Net Worth'] = '-$formatted';
          break;
        case 'loan_receivable':
          impact['Cash'] = '-$formatted';
          impact['Loan Receivables'] = '+$formatted';
          impact['Net Worth'] = 'No change (asset swap)';
          break;
        case 'loan_payable':
          impact['Cash'] = '+$formatted';
          impact['Liabilities'] = '+$formatted';
          impact['Net Worth'] = '-$formatted';
          break;
        case 'new_investment':
        case 'additional_investment':
          impact['Cash'] = '-$formatted';
          impact['Investment Portfolio'] = '+$formatted';
          impact['Net Worth'] = 'No change (asset swap)';
          break;
        case 'fixed_asset':
        case 'current_asset':
        case 'personal_asset':
          impact['Asset Register'] = '+$formatted';
          impact['Net Worth'] = '+$formatted';
          break;
        case 'transfer':
          impact['Account Balances'] = 'Rebalanced';
          impact['Net Worth'] = 'No change';
          break;
      }
    }
    return impact;
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return 'TZS ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) return 'TZS ${(amount / 1000).toStringAsFixed(0)}K';
    return 'TZS ${amount.toStringAsFixed(0)}';
  }

  // ─── COMMIT ENGINE (TIE Stage 8) ──────────────────────────────────────────

  Future<CommitResult> commit({
    required RegistrationCategory category,
    required String registrationType,
    required Map<String, dynamic> formData,
    required Map<String, dynamic> relationships,
    required OwnershipType ownershipType,
  }) async {
    final userId = _userId;
    if (userId == null) {
      return const CommitResult(
        success: false,
        errorMessage: 'User not authenticated',
      );
    }

    final startTime = DateTime.now();
    String? auditId;

    try {
      // Log initiation
      auditId = await _logAudit(
        category: category,
        type: registrationType,
        action: 'initiated',
        snapshot: {'form_data': formData, 'relationships': relationships},
      );

      // Merge form data with relationships
      final mergedData = {...formData, ...relationships, 'user_id': userId};

      CommitResult result;

      switch (category) {
        case RegistrationCategory.transaction:
          result = await _commitTransaction(
            registrationType,
            mergedData,
            userId,
          );
          break;
        case RegistrationCategory.business:
          result = await _commitBusiness(registrationType, mergedData, userId);
          break;
        case RegistrationCategory.investment:
          result = await _commitInvestment(
            registrationType,
            mergedData,
            userId,
          );
          break;
        case RegistrationCategory.asset:
          result = await _commitAsset(registrationType, mergedData, userId);
          break;
        case RegistrationCategory.loan:
          result = await _commitLoan(registrationType, mergedData, userId);
          break;
        case RegistrationCategory.organization:
          result = await _commitOrganization(
            registrationType,
            mergedData,
            userId,
          );
          break;
      }

      if (result.success) {
        // Log successful commit
        final duration = DateTime.now().difference(startTime).inMilliseconds;
        await _logAudit(
          category: category,
          type: registrationType,
          action: 'committed',
          entityId: result.entityId,
          entityTable: result.entityTable,
          snapshot: result.createdRecord ?? {},
          relatedModules: result.syncedModules.keys.toList(),
          durationMs: duration,
        );

        // Mark draft complete
        await markDraftComplete(category, registrationType);

        // ── ESE: Trigger Enterprise Synchronization Engine ──────────────────
        // Runs immediately after successful commit — updates all related modules
        if (result.entityId != null && result.entityTable != null) {
          EnterpriseSyncEngine.instance
              .synchronize(
                entityType: category.name,
                entityId: result.entityId!,
                entityTable: result.entityTable!,
                action: 'create',
                afterValues: result.createdRecord ?? mergedData,
              )
              .catchError((e) {
                debugPrint('[URE] ESE sync error (non-blocking): $e');
              });
        }
      } else {
        await _logAudit(
          category: category,
          type: registrationType,
          action: 'failed',
          errorMessage: result.errorMessage,
        );
      }

      return result;
    } catch (e) {
      await _logAudit(
        category: category,
        type: registrationType,
        action: 'rolled_back',
        errorMessage: e.toString(),
      );
      return CommitResult(
        success: false,
        errorMessage: 'Registration failed: ${e.toString()}',
      );
    }
  }

  // ─── TRANSACTION COMMIT ────────────────────────────────────────────────────

  Future<CommitResult> _commitTransaction(
    String type,
    Map<String, dynamic> data,
    String userId,
  ) async {
    try {
      String txnType;
      switch (type) {
        case 'income':
        case 'salary':
        case 'commission':
        case 'bonus':
        case 'dividend':
        case 'interest':
        case 'refund':
          txnType = 'income';
          break;
        case 'expense':
        case 'fees':
        case 'tax':
        case 'donation':
          txnType = 'expense';
          break;
        case 'transfer':
          txnType = 'transfer';
          break;
        default:
          txnType = type;
      }

      final txn = await _finance.createTransaction(
        type: txnType,
        category: data['category'] ?? type,
        amount: double.tryParse(data['amount']?.toString() ?? '0') ?? 0,
        date:
            DateTime.tryParse(data['transaction_date']?.toString() ?? '') ??
            DateTime.now(),
        accountId: data['account_id'],
        description: data['description'],
        notes: data['notes'],
        relatedBusinessId: data['related_business_id'],
        relatedInvestmentId: data['related_investment_id'],
        relatedGoalId: data['related_goal_id'],
        currency: data['currency'] ?? 'TZS',
      );

      if (txn == null) {
        return const CommitResult(
          success: false,
          errorMessage: 'Failed to save transaction',
        );
      }

      // For transfers: create the destination credit entry
      if (type == 'transfer' && data['destination_account_id'] != null) {
        await _finance.createTransaction(
          type: 'income',
          category: 'transfer',
          amount: double.tryParse(data['amount']?.toString() ?? '0') ?? 0,
          date:
              DateTime.tryParse(data['transaction_date']?.toString() ?? '') ??
              DateTime.now(),
          accountId: data['destination_account_id'],
          description: 'Transfer from ${data['description'] ?? 'account'}',
          notes: data['notes'],
          referenceId: txn['id'],
          currency: data['currency'] ?? 'TZS',
        );
      }

      return CommitResult(
        success: true,
        entityId: txn['id'],
        entityTable: 'financial_transactions',
        createdRecord: txn,
        syncedModules: {
          'Finance Engine': true,
          'Dashboard': true,
          'Transaction History': true,
          'Net Worth': true,
        },
      );
    } catch (e) {
      return CommitResult(success: false, errorMessage: e.toString());
    }
  }

  // ─── BUSINESS COMMIT ───────────────────────────────────────────────────────

  Future<CommitResult> _commitBusiness(
    String type,
    Map<String, dynamic> data,
    String userId,
  ) async {
    try {
      if (type == 'business_registration') {
        final res = await _client
            .from('businesses')
            .insert({
              'owner_id': userId,
              'name': data['name'],
              'business_type': data['business_type'],
              'industry': data['industry'],
              'registration_number': data['registration_number'],
              'description': data['description'],
              'is_active': true,
            })
            .select()
            .single();

        return CommitResult(
          success: true,
          entityId: res['id'],
          entityTable: 'businesses',
          createdRecord: res,
          syncedModules: {
            'Business Dashboard': true,
            'Finance Engine': true,
            'Dashboard': true,
          },
        );
      }

      // Business income/expense → create as financial transaction linked to business
      final txnType = (type == 'business_income') ? 'income' : 'expense';
      final txn = await _finance.createTransaction(
        type: txnType,
        category: data['category'] ?? type,
        amount: double.tryParse(data['amount']?.toString() ?? '0') ?? 0,
        date:
            DateTime.tryParse(data['transaction_date']?.toString() ?? '') ??
            DateTime.now(),
        accountId: data['account_id'],
        description: data['description'],
        notes: data['notes'],
        relatedModule: 'business',
        relatedBusinessId: data['related_business_id'],
        currency: data['currency'] ?? 'TZS',
      );

      if (txn == null) {
        return const CommitResult(
          success: false,
          errorMessage: 'Failed to save business transaction',
        );
      }

      return CommitResult(
        success: true,
        entityId: txn['id'],
        entityTable: 'financial_transactions',
        createdRecord: txn,
        syncedModules: {
          'Business Dashboard': true,
          'Business Ledger': true,
          'Finance Engine': true,
          'Dashboard': true,
          'Net Worth': true,
        },
      );
    } catch (e) {
      return CommitResult(success: false, errorMessage: e.toString());
    }
  }

  // ─── INVESTMENT COMMIT ─────────────────────────────────────────────────────

  Future<CommitResult> _commitInvestment(
    String type,
    Map<String, dynamic> data,
    String userId,
  ) async {
    try {
      if (type == 'new_investment' || type == 'additional_investment') {
        final res = await _client
            .from('investments')
            .insert({
              'user_id': userId,
              'name': data['name'],
              'category': data['category'],
              'initial_value':
                  double.tryParse(data['initial_value']?.toString() ?? '0') ??
                  0,
              'current_value':
                  double.tryParse(data['current_value']?.toString() ?? '0') ??
                  0,
              'expected_return_rate':
                  double.tryParse(
                    data['expected_return_rate']?.toString() ?? '0',
                  ) ??
                  0,
              'risk_level': data['risk_level'] ?? 'medium',
              'investment_date':
                  data['investment_date'] ??
                  DateTime.now().toIso8601String().split('T')[0],
              'description': data['description'],
              'status': 'active',
            })
            .select()
            .single();

        // Also create a transaction for the capital outflow
        final amount =
            double.tryParse(data['initial_value']?.toString() ?? '0') ?? 0;
        if (amount > 0 && data['account_id'] != null) {
          await _finance.createTransaction(
            type: 'expense',
            category: 'investment',
            amount: amount,
            date:
                DateTime.tryParse(data['investment_date']?.toString() ?? '') ??
                DateTime.now(),
            accountId: data['account_id'],
            description: 'Investment: ${data['name']}',
            relatedModule: 'investment',
            relatedInvestmentId: res['id'],
            currency: data['currency'] ?? 'TZS',
          );
        }

        return CommitResult(
          success: true,
          entityId: res['id'],
          entityTable: 'investments',
          createdRecord: res,
          syncedModules: {
            'Investment Portfolio': true,
            'Asset Register': true,
            'Finance Engine': true,
            'Net Worth': true,
            'Dashboard': true,
            'AI Brain': true,
          },
        );
      }

      if (type == 'investment_valuation') {
        final investmentId = data['investment_id'];
        if (investmentId == null) {
          return const CommitResult(
            success: false,
            errorMessage: 'Investment ID is required',
          );
        }
        await _client
            .from('investments')
            .update({
              'current_value':
                  double.tryParse(data['current_value']?.toString() ?? '0') ??
                  0,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', investmentId);

        return CommitResult(
          success: true,
          entityId: investmentId,
          entityTable: 'investments',
          syncedModules: {
            'Investment Portfolio': true,
            'Net Worth': true,
            'Dashboard': true,
          },
        );
      }

      // Investment return/dividend/withdrawal → financial transaction
      final txnType = (type == 'investment_withdrawal') ? 'expense' : 'income';
      final txn = await _finance.createTransaction(
        type: txnType,
        category: type,
        amount: double.tryParse(data['amount']?.toString() ?? '0') ?? 0,
        date:
            DateTime.tryParse(data['transaction_date']?.toString() ?? '') ??
            DateTime.now(),
        accountId: data['account_id'],
        description: data['description'] ?? type.replaceAll('_', ' '),
        relatedModule: 'investment',
        relatedInvestmentId: data['investment_id'],
        currency: data['currency'] ?? 'TZS',
      );

      return CommitResult(
        success: txn != null,
        entityId: txn?['id'],
        entityTable: 'financial_transactions',
        createdRecord: txn,
        errorMessage: txn == null
            ? 'Failed to save investment transaction'
            : null,
        syncedModules: {
          'Investment Portfolio': true,
          'Finance Engine': true,
          'Net Worth': true,
        },
      );
    } catch (e) {
      return CommitResult(success: false, errorMessage: e.toString());
    }
  }

  // ─── ASSET COMMIT ──────────────────────────────────────────────────────────

  Future<CommitResult> _commitAsset(
    String type,
    Map<String, dynamic> data,
    String userId,
  ) async {
    try {
      final categoryMap = {
        'fixed_asset': 'fixed',
        'current_asset': 'current',
        'financial_asset': 'financial',
        'digital_asset': 'digital',
        'business_asset': 'fixed',
        'personal_asset': 'current',
      };

      final res = await _client
          .from('assets')
          .insert({
            'user_id': userId,
            'asset_name': data['asset_name'],
            'asset_category': categoryMap[type] ?? 'fixed',
            'asset_type': data['asset_type'] ?? 'other',
            'purchase_price':
                double.tryParse(data['purchase_price']?.toString() ?? '0') ?? 0,
            'current_value':
                double.tryParse(data['current_value']?.toString() ?? '0') ?? 0,
            'purchase_date': data['purchase_date'],
            'description': data['description'],
            'notes': data['notes'],
            'related_business_id': data['related_business_id'],
            'ownership_type': data['ownership_type'] ?? 'individual',
            'is_active': true,
          })
          .select()
          .single();

      return CommitResult(
        success: true,
        entityId: res['id'],
        entityTable: 'assets',
        createdRecord: res,
        syncedModules: {
          'Asset Register': true,
          'Finance Engine': true,
          'Net Worth': true,
          'Dashboard': true,
        },
      );
    } catch (e) {
      return CommitResult(success: false, errorMessage: e.toString());
    }
  }

  // ─── LOAN COMMIT ───────────────────────────────────────────────────────────

  Future<CommitResult> _commitLoan(
    String type,
    Map<String, dynamic> data,
    String userId,
  ) async {
    try {
      if (type == 'loan_receivable') {
        final principal =
            double.tryParse(data['principal_amount']?.toString() ?? '0') ?? 0;
        final res = await _client
            .from('loans_receivable')
            .insert({
              'user_id': userId,
              'borrower_name': data['borrower_name'],
              'borrower_phone': data['borrower_phone'],
              'principal_amount': principal,
              'outstanding_balance': principal,
              'interest_rate':
                  double.tryParse(data['interest_rate']?.toString() ?? '0') ??
                  0,
              'interest_type': data['interest_type'] ?? 'simple',
              'issue_date': data['issue_date'],
              'due_date': data['due_date'],
              'collateral': data['collateral'],
              'notes': data['notes'],
              'status': 'active',
            })
            .select()
            .single();

        // Debit the disbursing account
        if (data['account_id'] != null && principal > 0) {
          await _finance.createTransaction(
            type: 'expense',
            category: 'loan_issued',
            amount: principal,
            date:
                DateTime.tryParse(data['issue_date']?.toString() ?? '') ??
                DateTime.now(),
            accountId: data['account_id'],
            description: 'Loan to ${data['borrower_name']}',
            relatedModule: 'loan_receivable',
            relatedLoanReceivableId: res['id'],
            currency: data['currency'] ?? 'TZS',
          );
        }

        return CommitResult(
          success: true,
          entityId: res['id'],
          entityTable: 'loans_receivable',
          createdRecord: res,
          syncedModules: {
            'Loan Receivables': true,
            'Asset Register': true,
            'Finance Engine': true,
            'Net Worth': true,
            'Dashboard': true,
          },
        );
      }

      if (type == 'loan_payable') {
        final principal =
            double.tryParse(data['principal_amount']?.toString() ?? '0') ?? 0;
        final res = await _client
            .from('loans')
            .insert({
              'user_id': userId,
              'loan_name': 'Loan from ${data['lender_name']}',
              'lender_name': data['lender_name'],
              'principal_amount': principal,
              'outstanding_balance': principal,
              'interest_rate':
                  double.tryParse(data['interest_rate']?.toString() ?? '0') ??
                  0,
              'interest_type': data['interest_type'] ?? 'simple',
              'start_date': data['issue_date'],
              'due_date': data['due_date'],
              'purpose': data['purpose'],
              'notes': data['notes'],
              'loan_type': 'personal',
              'status': 'active',
            })
            .select()
            .single();

        // Credit the receiving account
        if (data['account_id'] != null && principal > 0) {
          await _finance.createTransaction(
            type: 'income',
            category: 'loan_received',
            amount: principal,
            date:
                DateTime.tryParse(data['issue_date']?.toString() ?? '') ??
                DateTime.now(),
            accountId: data['account_id'],
            description: 'Loan from ${data['lender_name']}',
            relatedModule: 'loan',
            relatedLoanId: res['id'],
            currency: data['currency'] ?? 'TZS',
          );
        }

        return CommitResult(
          success: true,
          entityId: res['id'],
          entityTable: 'loans',
          createdRecord: res,
          syncedModules: {
            'Loan Dashboard': true,
            'Finance Engine': true,
            'Net Worth': true,
            'Dashboard': true,
          },
        );
      }

      // Repayments
      if (type == 'loan_repayment' ||
          type == 'partial_repayment' ||
          type == 'interest_payment') {
        final amount = double.tryParse(data['amount']?.toString() ?? '0') ?? 0;
        final loanId = data['loan_id'];

        if (loanId != null && amount > 0) {
          // Reduce outstanding balance
          final loan = await _client
              .from('loans')
              .select('outstanding_balance')
              .eq('id', loanId)
              .maybeSingle();
          if (loan != null) {
            final current =
                (loan['outstanding_balance'] as num?)?.toDouble() ?? 0;
            final newBalance = (current - amount).clamp(0, double.infinity);
            await _client
                .from('loans')
                .update({
                  'outstanding_balance': newBalance,
                  'status': newBalance <= 0 ? 'settled' : 'active',
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', loanId);
          }
        }

        final txn = await _finance.createTransaction(
          type: 'expense',
          category: 'loan_repayment',
          amount: amount,
          date:
              DateTime.tryParse(data['payment_date']?.toString() ?? '') ??
              DateTime.now(),
          accountId: data['account_id'],
          description: 'Loan repayment',
          relatedModule: 'loan',
          relatedLoanId: loanId,
          currency: data['currency'] ?? 'TZS',
        );

        return CommitResult(
          success: txn != null,
          entityId: txn?['id'],
          entityTable: 'financial_transactions',
          createdRecord: txn,
          errorMessage: txn == null ? 'Failed to save repayment' : null,
          syncedModules: {
            'Loan Dashboard': true,
            'Finance Engine': true,
            'Net Worth': true,
          },
        );
      }

      return const CommitResult(
        success: false,
        errorMessage: 'Unsupported loan type',
      );
    } catch (e) {
      return CommitResult(success: false, errorMessage: e.toString());
    }
  }

  // ─── ORGANIZATION COMMIT ───────────────────────────────────────────────────

  Future<CommitResult> _commitOrganization(
    String type,
    Map<String, dynamic> data,
    String userId,
  ) async {
    try {
      final res = await _client
          .from('organizations')
          .insert({
            'owner_id': userId,
            'name': data['name'],
            'org_type': data['org_type'] ?? 'company',
            'description': data['description'],
            'registration_number': data['registration_number'],
            'is_active': true,
          })
          .select()
          .single();

      return CommitResult(
        success: true,
        entityId: res['id'],
        entityTable: 'organizations',
        createdRecord: res,
        syncedModules: {
          'Organization Dashboard': true,
          'Finance Engine': true,
          'Dashboard': true,
        },
      );
    } catch (e) {
      return CommitResult(success: false, errorMessage: e.toString());
    }
  }

  // ─── AUDIT LOGGING ─────────────────────────────────────────────────────────

  Future<String?> _logAudit({
    required RegistrationCategory category,
    required String type,
    required String action,
    String? entityId,
    String? entityTable,
    Map<String, dynamic>? snapshot,
    List<String>? relatedModules,
    String? errorMessage,
    int? durationMs,
  }) async {
    final userId = _userId;
    if (userId == null) return null;
    try {
      final res = await _client
          .from('registration_audit_log')
          .insert({
            'user_id': userId,
            'registration_category': category.name,
            'registration_type': type,
            'action': action,
            'entity_table': entityTable,
            'entity_id': entityId,
            'snapshot': snapshot ?? {},
            'related_modules': relatedModules ?? [],
            'error_message': errorMessage,
            'duration_ms': durationMs,
          })
          .select('id')
          .single();
      return res['id'] as String?;
    } catch (_) {
      return null;
    }
  }
}
