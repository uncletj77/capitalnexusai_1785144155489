import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../routes/app_routes.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _selectedUserType;
  String? _selectedGoal;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;

  final List<Map<String, dynamic>> _userTypes = [
    {
      'id': 'individual',
      'title': 'Individual',
      'subtitle': 'Personal wealth & finances',
      'icon': 'person',
      'color': const Color(0xFF2D9CDB),
    },
    {
      'id': 'entrepreneur',
      'title': 'Entrepreneur',
      'subtitle': 'Multiple businesses & assets',
      'icon': 'business_center',
      'color': const Color(0xFF8B5CF6),
    },
    {
      'id': 'organization',
      'title': 'Organization',
      'subtitle': 'Teams, departments & operations',
      'icon': 'corporate_fare',
      'color': const Color(0xFF10B981),
    },
    {
      'id': 'investor',
      'title': 'Investor',
      'subtitle': 'Portfolio & investment tracking',
      'icon': 'trending_up',
      'color': const Color(0xFFF59E0B),
    },
  ];

  final List<Map<String, dynamic>> _goals = [
    {
      'id': 'wealth',
      'title': 'Manage my wealth',
      'icon': 'account_balance',
      'color': const Color(0xFF2D9CDB),
    },
    {
      'id': 'business',
      'title': 'Grow my business',
      'icon': 'store',
      'color': const Color(0xFF8B5CF6),
    },
    {
      'id': 'investments',
      'title': 'Track investments',
      'icon': 'show_chart',
      'color': const Color(0xFF10B981),
    },
    {
      'id': 'assets',
      'title': 'Manage assets',
      'icon': 'real_estate_agent',
      'color': const Color(0xFFF59E0B),
    },
    {
      'id': 'loans',
      'title': 'Control my loans',
      'icon': 'credit_score',
      'color': const Color(0xFFEC4899),
    },
    {
      'id': 'goals',
      'title': 'Achieve financial goals',
      'icon': 'flag',
      'color': const Color(0xFF4BB8A0),
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.go(AppRoutes.dashboardScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // Animated background
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.3),
                  radius: 1.2,
                  colors: [Color(0x551A5F7A), Color(0x00111827)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'C',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Capital NEXUS AI',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      if (_currentPage > 0)
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.dashboardScreen),
                          child: Text(
                            'Skip',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white54,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Page indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: List.generate(3, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: i == _currentPage ? 24 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? AppTheme.primaryLight
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) {
                      setState(() => _currentPage = i);
                      _slideController.reset();
                      _slideController.forward();
                    },
                    children: [
                      _buildWelcomePage(),
                      _buildUserTypePage(),
                      _buildGoalPage(),
                    ],
                  ),
                ),
                // Bottom button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: _buildContinueButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _slideController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2D9CDB).withAlpha(80),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.asset(
                      'assets/images/1784984410523-1785010529681.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Capital NEXUS AI',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your Wealth. One Intelligent\nCommand Center.',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white60,
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Feature pills
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _FeaturePill(
                    icon: 'account_balance',
                    label: 'Wealth Tracking',
                  ),
                  _FeaturePill(
                    icon: 'business',
                    label: 'Business Intelligence',
                  ),
                  _FeaturePill(icon: 'psychology', label: 'AI Advisor'),
                  _FeaturePill(
                    icon: 'show_chart',
                    label: 'Investment Analytics',
                  ),
                  _FeaturePill(
                    icon: 'real_estate_agent',
                    label: 'Asset Management',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypePage() {
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _slideController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Who are you?',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'CNA adapts to your profile for personalized intelligence.',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _userTypes.length,
                  itemBuilder: (context, i) {
                    final type = _userTypes[i];
                    final isSelected = _selectedUserType == type['id'];
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedUserType = type['id']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (type['color'] as Color).withAlpha(40)
                              : Colors.white.withAlpha(8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? (type['color'] as Color)
                                : Colors.white.withAlpha(20),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: (type['color'] as Color).withAlpha(30),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: CustomIconWidget(
                                    iconName: type['icon'] as String,
                                    color: type['color'] as Color,
                                    size: 20,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type['title'] as String,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    type['subtitle'] as String,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalPage() {
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _slideController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'What\'s your goal?',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your primary focus. You can change this anytime.',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _goals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final goal = _goals[i];
                    final isSelected = _selectedGoal == goal['id'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedGoal = goal['id']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (goal['color'] as Color).withAlpha(30)
                              : Colors.white.withAlpha(8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? (goal['color'] as Color)
                                : Colors.white.withAlpha(15),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: (goal['color'] as Color).withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: CustomIconWidget(
                                  iconName: goal['icon'] as String,
                                  color: goal['color'] as Color,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                goal['title'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: goal['color'] as Color,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    final bool canProceed =
        _currentPage == 0 ||
        (_currentPage == 1 && _selectedUserType != null) ||
        (_currentPage == 2 && _selectedGoal != null);

    return Column(
      children: [
        GestureDetector(
          onTap: canProceed ? _nextPage : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              gradient: canProceed
                  ? const LinearGradient(
                      colors: [Color(0xFF1A5F7A), Color(0xFF2D9CDB)],
                    )
                  : null,
              color: canProceed ? null : Colors.white12,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Center(
              child: Text(
                _currentPage == 2 ? 'Enter Capital NEXUS AI' : 'Continue',
                style: GoogleFonts.plusJakartaSans(
                  color: canProceed ? Colors.white : Colors.white38,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
        if (_currentPage == 0) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => context.go(AppRoutes.loginScreen),
                child: Text(
                  'Sign In',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.primaryLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '  ·  ',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white38,
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.registrationScreen),
                child: Text(
                  'Create Account',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final String icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: icon,
            color: AppTheme.primaryLight,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(8)
      ..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
