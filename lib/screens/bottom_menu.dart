import 'package:flutter/material.dart';
import 'package:habita/screens/home_screen.dart';
import '../constants/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      HomeScreen(),
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
            child: Container(
              height: screenHeight < 700 ? 65 : 75,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide( color: const Color(0xFFEDEDED), width: 1,)),
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
                    assetPath: 'assets/icons/home.svg',
                    currentIndex: activeIndex,
                    screenWidth: screenWidth,
                  ),
                  _navItem(
                    context: context,
                    index: 1,
                    assetPath: 'assets/icons/activity.svg',
                    currentIndex: activeIndex,
                    screenWidth: screenWidth,
                  ),
                  _navItem(
                    context: context,
                    index: 2,
                    assetPath: 'assets/icons/settings.svg',
                    currentIndex: activeIndex,
                    screenWidth: screenWidth,
                  ),
                ],
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
    required String assetPath,
    required int currentIndex,
    required double screenWidth,
  }) {
    final bool isSelected = currentIndex == index;
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
            isSelected
                ? ShaderMask(
              shaderCallback: (Rect bounds) {
                return AppColors.orangeGradient.createShader(bounds);
              },
              blendMode: BlendMode.srcIn,
              child: SvgPicture.asset(
                assetPath,
                height: 26,
                width: 26,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            )
                : SvgPicture.asset(
              assetPath,
              height: 26,
              width: 26,
              colorFilter: ColorFilter.mode(
                inactiveColor,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}