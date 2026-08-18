import 'package:flutter/material.dart';

class TianKeyBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const TianKeyBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFF050E18),
        border: Border(
          top: BorderSide(
            color: Colors.blueAccent.withOpacity(0.35),
          ),
        ),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: const Color(0xFF050E18),
          indicatorColor: Colors.blueAccent.withOpacity(0.18),
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            return TextStyle(
              color: states.contains(MaterialState.selected)
                  ? Colors.blueAccent
                  : Colors.white54,
              fontSize: 12,
              fontWeight: states.contains(MaterialState.selected)
                  ? FontWeight.bold
                  : FontWeight.normal,
            );
          }),
          iconTheme: MaterialStateProperty.resolveWith((states) {
            return IconThemeData(
              color: states.contains(MaterialState.selected)
                  ? Colors.blueAccent
                  : Colors.white54,
              size: states.contains(MaterialState.selected) ? 26 : 24,
            );
          }),
        ),
        child: NavigationBar(
          height: 70,
          elevation: 0,
          selectedIndex: currentIndex,
          onDestinationSelected: onChanged,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: '首页',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: '临时借车',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: '设置',
            ),
          ],
        ),
      ),
    );
  }
}
