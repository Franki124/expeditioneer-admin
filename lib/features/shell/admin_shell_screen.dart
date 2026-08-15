import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../analytics/presentation/analytics_screen.dart';
import '../assets/presentation/assets_screen.dart';
import '../auth/cubit/admin_auth_cubit.dart';
import '../events/domain/admin_event.dart';
import '../events/presentation/events_screen.dart';
import '../leaderboard/presentation/leaderboard_screen.dart';
import '../participants/presentation/participants_screen.dart';
import '../quests/presentation/quests_screen.dart';

enum _Section {
  events('Events', Icons.event),
  quests('Quests', Icons.map),
  leaderboard('Leaderboard', Icons.leaderboard),
  analytics('Analytics', Icons.bar_chart),
  assets('Assets', Icons.perm_media),
  participants('Participants', Icons.people);

  const _Section(this.label, this.icon);
  final String label;
  final IconData icon;
}

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  _Section _selected = _Section.events;
  String? _preselectedParticipantsEventId;

  void _viewParticipants(AdminEvent event) {
    setState(() {
      _selected = _Section.participants;
      _preselectedParticipantsEventId = event.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AdminAuthCubit>().state.profile;
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: AppColors.navyPanel,
            minWidth: 92,
            selectedIndex: _Section.values.indexOf(_selected),
            onDestinationSelected: (index) => setState(() => _selected = _Section.values[index]),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg28),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 1.5),
                    ),
                    child: Text('E', style: AppTypography.display(fontSize: 18, color: AppColors.gold)),
                  ),
                  const SizedBox(height: AppSpacing.xs8),
                  Text('ADMIN', style: AppTypography.body(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.gold)),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md20),
                  child: IconButton(
                    tooltip: profile == null ? 'Sign out' : 'Sign out (${profile.role})',
                    icon: const Icon(Icons.logout),
                    onPressed: () => context.read<AdminAuthCubit>().signOut(),
                  ),
                ),
              ),
            ),
            destinations: [
              for (final section in _Section.values)
                NavigationRailDestination(
                  icon: Icon(section.icon),
                  label: Text(section.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1, color: AppColors.navyDeep),
          Expanded(child: _buildSection(_selected)),
        ],
      ),
    );
  }

  Widget _buildSection(_Section section) {
    return switch (section) {
      _Section.events => EventsScreen(onViewParticipants: _viewParticipants),
      _Section.quests => const QuestsScreen(),
      _Section.assets => const AssetsScreen(),
      _Section.leaderboard => const LeaderboardScreen(),
      _Section.participants => ParticipantsScreen(initialEventId: _preselectedParticipantsEventId),
      _Section.analytics => const AnalyticsScreen(),
    };
  }
}
