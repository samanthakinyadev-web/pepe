import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MenuItem {
  final String id;
  final String title;
  final IconData icon;
  final bool isComingSoon;
  final String? apiEndpoint; // Will be configured later

  MenuItem({
    required this.id,
    required this.title,
    required this.icon,
    this.isComingSoon = false,
    this.apiEndpoint,
  });

  // Predefined menu items (will fetch from API later)
  static List<MenuItem> getDefaultMenuItems() {
    return [
      MenuItem(
        id: 'learning_areas',
        title: 'My Learning Areas',
        icon: FontAwesomeIcons.bookOpen,
        isComingSoon: false,
      ),
      MenuItem(
        id: 'interactive_books',
        title: 'Interactive Books',
        icon: FontAwesomeIcons.laptopCode,
        isComingSoon: false,
      ),
      MenuItem(
        id: 'non_interactive_books',
        title: 'Non-Interactive Books',
        icon: FontAwesomeIcons.book,
        isComingSoon: false,
      ),
      MenuItem(
        id: 'data_learning',
        title: 'Dals Learning',
        icon: FontAwesomeIcons.chartSimple,
        isComingSoon: false,
      ),
      MenuItem(
        id: 'esoma_kids',
        title: 'Esoma Kids',
        icon: FontAwesomeIcons.childReaching,
        isComingSoon: false,
      ),
      MenuItem(
        id: 'virtual_labs',
        title: 'Virtual Labs',
        icon: FontAwesomeIcons.flask,
        isComingSoon: false,
      ),
      MenuItem(
        id: 'elimu_quest',
        title: 'Elimu Quest',
        icon: FontAwesomeIcons.flag,
        isComingSoon: false,
      ),
      MenuItem(
        id: 'leaderboard',
        title: 'Leaderboard',
        icon: FontAwesomeIcons.trophy,
        isComingSoon: false,
      ),
      MenuItem(
        id: 'loho_tv',
        title: 'Loho TV',
        icon: FontAwesomeIcons.tv,
        isComingSoon: false,
      ),
      MenuItem(
        id: 'live_classes',
        title: 'Live Classes',
        icon: FontAwesomeIcons.graduationCap,
        isComingSoon: true,
      ),
      MenuItem(
        id: 'games',
        title: 'Games',
        icon: FontAwesomeIcons.gamepad,
        isComingSoon: false,
      ),
      MenuItem(
        id: 'my_questions',
        title: 'My Questions',
        icon: FontAwesomeIcons.circleQuestion,
        isComingSoon: false,
      ),
    ];
  }
}
