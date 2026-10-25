import 'package:flutter/material.dart';
import 'core/settings.dart';
import 'core/theme.dart';
import 'core/theme_filter.dart';
import 'features/home/home_screen.dart';
import 'features/discover/discover_screen.dart';
import 'features/weekly_plan/weekly_plan_screen.dart';
import 'features/goals/goals_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.instance.load();
  runApp(const FocusPathApp());
}

class FocusPathApp extends StatelessWidget {
  const FocusPathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) => MaterialApp(
        title: 'FocusPath',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return AppColorFilter(
            child: MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(AppSettings.instance.fontScale),
              ),
              child: child!,
            ),
          );
        },
        home: const MainShell(),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onGoToTab: (i) => setState(() => _index = i)),
      const DiscoverScreen(),
      const WeeklyPlanScreen(),
      const GoalsScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Discover'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Plan'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}