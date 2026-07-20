import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class BottomMenuController {
  final ValueNotifier<int> currentIndex = ValueNotifier<int>(0);

  void changeIndex(int index) {
    currentIndex.value = index;
  }

  void dispose() {
    currentIndex.dispose();
  }
}

class BottomMenu extends StatelessWidget {
  final BottomMenuController controller = BottomMenuController();
  BottomMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    final List<Widget> pages = [
      const Center(child: Text("Home Page")),
      const Center(child: Text("Activity Page")),
      const Center(child: Text("Settings Page")),
    ];

    return ValueListenableBuilder<int>(
      valueListenable: controller.currentIndex,
      builder: (context, activeIndex, _) {
        return Scaffold(
          backgroundColor: AppColors.grey,
          body: IndexedStack(index: activeIndex, children: pages),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20.0,
                0.0,
                20.0,
                bottomPadding > 0 ? bottomPadding * 0.4 : 16.0,
              ),
              child: Container(
                height: screenHeight < 700 ? 65 : 75,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(
                    color: const Color(0xFFEDEDED),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _navItem(
                      context: context,
                      index: 0,
                      outlineIcon: Icons.home_outlined,
                      filledIcon: Icons.home_rounded,
                      currentIndex: activeIndex,
                      screenWidth: screenWidth,
                    ),
                    _navItem(
                      context: context,
                      index: 1,
                      outlineIcon: Icons.monitor_heart_outlined,
                      filledIcon: Icons.monitor_heart_rounded,
                      currentIndex: activeIndex,
                      screenWidth: screenWidth,
                    ),
                    _navItem(
                      context: context,
                      index: 2,
                      outlineIcon: Icons.settings_outlined,
                      filledIcon: Icons.settings_rounded,
                      currentIndex: activeIndex,
                      screenWidth: screenWidth,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _navItem({
    required BuildContext context,
    required int index,
    required IconData outlineIcon,
    required IconData filledIcon,
    required int currentIndex,
    required double screenWidth,
  }) {
    final bool isSelected = currentIndex == index;
    final Color activeColor = AppColors.orange;
    final Color inactiveColor = const Color(0xFF8A9A93);

    final double computedWidth = screenWidth * 0.22;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        controller.changeIndex(index);
      },
      child: SizedBox(
        width: computedWidth < 60 ? 60 : (computedWidth > 80 ? 80 : computedWidth),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? filledIcon : outlineIcon,
              color: isSelected ? activeColor : inactiveColor,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}