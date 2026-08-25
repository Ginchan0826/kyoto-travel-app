import 'package:flutter/material.dart';

import '../../browse/presentation/browse_page.dart';
import '../../itinerary/presentation/itinerary_list_page.dart';
import '../../spots/presentation/nearby_spots_page.dart';
import '../../touring/presentation/touring_itinerary_list_page.dart';

/// アプリのルート画面。画面下部のタブで「しおり」「観光」「閲覧」「検索」を切り替える。
/// 各タブは実際に開くまで中身を構築しない（ログイン直後に全タブのデータ取得が
/// 同時に走り、認証情報の伝播が間に合わず permission-denied になるのを防ぐため）。
class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _currentIndex = 0;
  final Set<int> _visitedIndexes = {0};

  static const _pages = [
    ItineraryListPage(),
    TouringItineraryListPage(),
    BrowsePage(),
    NearbySpotsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          for (var i = 0; i < _pages.length; i++)
            _visitedIndexes.contains(i) ? _pages[i] : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
            _visitedIndexes.add(index);
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'しおり',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: '観光',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: '閲覧',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: '検索',
          ),
        ],
      ),
    );
  }
}
