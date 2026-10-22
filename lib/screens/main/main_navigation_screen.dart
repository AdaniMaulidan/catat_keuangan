import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../dashboard/dashboard_screen.dart';
import '../calendar/calendar_screen.dart';
import '../chart/chart_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardScreen(),
    const CalendarScreen(),
    const ChartScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          border: const Border(
            top: BorderSide(color: AppTheme.slate100, width: 1),
          ),
          boxShadow: AppTheme.navShadow,
        ),
        child: SafeArea(
          top: false,
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildNavItem(
                  index: 0,
                  label: 'Dashboard',
                  icon: Icons.home_rounded,
                ),
                _buildNavItem(
                  index: 1,
                  label: 'Kalender',
                  icon: Icons.calendar_today_rounded,
                ),
                _buildNavItem(
                  index: 2,
                  label: 'Grafik',
                  icon: Icons.bar_chart_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppTheme.emerald600 : AppTheme.slate400;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        splashColor: AppTheme.emerald50,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
                if (isSelected)
                  Positioned(
                    bottom: -5,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppTheme.emerald600,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
