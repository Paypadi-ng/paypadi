import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:paypadi/config/router/router.gr.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: const [
        DashboardRoute(),
        TransactionHistoryRoute(),
        SettingsRoute(),
      ],
      builder: (context, child) {
        final TabsRouter tabsRouter = AutoTabsRouter.of(context);

        return Scaffold(
          body: SafeArea(child: child),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: tabsRouter.activeIndex,
            onTap: tabsRouter.setActiveIndex,
            items: const [
              BottomNavigationBarItem(
                label: 'Transfer',
                icon: Icon(Icons.arrow_downward_rounded),
              ),
              BottomNavigationBarItem(
                label: 'History',
                icon: Icon(Icons.history),
              ),
              BottomNavigationBarItem(
                label: 'Settings',
                icon: Icon(Icons.settings),
              ),
            ],
          ),
        );
      },
    );
  }
}
