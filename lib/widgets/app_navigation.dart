import 'package:flutter/material.dart';

import '../core/app_export.dart';

class _TabSpec {
  final String label;
  final String iconName;
  final String selectedIconName;
  final int? branchIndex;

  const _TabSpec({
    required this.label,
    required this.iconName,
    required this.selectedIconName,
    this.branchIndex,
  });
}

class AppNavigation extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppNavigation({required this.navigationShell, super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _selectedVisualIndex = 0;

  final List<_TabSpec> _tabs = const [
    _TabSpec(
      label: 'Home',
      iconName: 'home_outlined',
      selectedIconName: 'home',
      branchIndex: 0,
    ),
    _TabSpec(
      label: 'Assets',
      iconName: 'real_estate_agent',
      selectedIconName: 'real_estate_agent',
      branchIndex: 1,
    ),
    _TabSpec(
      label: 'Finance',
      iconName: 'account_balance_outlined',
      selectedIconName: 'account_balance',
      branchIndex: 2,
    ),
    _TabSpec(
      label: 'Business',
      iconName: 'business_center',
      selectedIconName: 'business_center',
      branchIndex: 3,
    ),
    _TabSpec(
      label: 'Invest',
      iconName: 'trending_up',
      selectedIconName: 'trending_up',
      branchIndex: 4,
    ),
    _TabSpec(
      label: 'AI',
      iconName: 'psychology_outlined',
      selectedIconName: 'psychology',
      branchIndex: 5,
    ),
    _TabSpec(
      label: 'Profile',
      iconName: 'person_outline',
      selectedIconName: 'person',
      branchIndex: 6,
    ),
  ];

  @override
  void didUpdateWidget(covariant AppNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shellIndex = widget.navigationShell.currentIndex;
    if (shellIndex != _selectedVisualIndex) {
      setState(() => _selectedVisualIndex = shellIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final tab = _tabs[i];
              final isActive = i == _selectedVisualIndex;
              final isAiTab = tab.label == 'AI';

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (tab.branchIndex == null) return;
                    setState(() => _selectedVisualIndex = i);
                    widget.navigationShell.goBranch(
                      tab.branchIndex!,
                      initialLocation:
                          tab.branchIndex ==
                          widget.navigationShell.currentIndex,
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      isAiTab
                          ? AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: isActive
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF1A5F7A),
                                          Color(0xFF2D9CDB),
                                        ],
                                      )
                                    : null,
                                color: isActive ? null : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: isActive
                                    ? null
                                    : Border.all(
                                        color: theme.colorScheme.outline,
                                      ),
                              ),
                              child: Center(
                                child: CustomIconWidget(
                                  iconName: isActive
                                      ? tab.selectedIconName
                                      : tab.iconName,
                                  color: isActive
                                      ? Colors.white
                                      : theme.colorScheme.onSurfaceVariant,
                                  size: 22,
                                ),
                              ),
                            )
                          : CustomIconWidget(
                              iconName: isActive
                                  ? tab.selectedIconName
                                  : tab.iconName,
                              color: isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              size: 22,
                            ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        child: isActive
                            ? Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  tab.label,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isAiTab && isActive
                                        ? const Color(0xFF1A5F7A)
                                        : theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        width: isActive ? 4 : 0,
                        height: isActive ? 4 : 0,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
