import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/auth/cubit/admin_auth_cubit.dart';
import 'features/auth/cubit/admin_auth_state.dart';
import 'features/auth/data/admin_auth_repository.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/events/data/asset_library_repository.dart';
import 'features/events/data/event_repository.dart';
import 'features/events/data/journal_repository.dart';
import 'features/events/data/participant_repository.dart';
import 'features/events/data/quest_library_repository.dart';
import 'features/shell/admin_shell_screen.dart';
import 'theme/app_theme.dart';

class AdminConsoleApp extends StatefulWidget {
  const AdminConsoleApp({super.key});

  @override
  State<AdminConsoleApp> createState() => _AdminConsoleAppState();
}

class _AdminConsoleAppState extends State<AdminConsoleApp> {
  late final AdminAuthRepository _authRepository;
  late final EventRepository _eventRepository;
  late final JournalRepository _journalRepository;
  late final ParticipantRepository _participantRepository;
  late final AssetLibraryRepository _assetLibraryRepository;
  late final QuestLibraryRepository _questLibraryRepository;
  late final AdminAuthCubit _authCubit;

  @override
  void initState() {
    super.initState();
    _authRepository = AdminAuthRepository();
    _eventRepository = EventRepository();
    _journalRepository = JournalRepository();
    _participantRepository = ParticipantRepository();
    _assetLibraryRepository = AssetLibraryRepository();
    _questLibraryRepository = QuestLibraryRepository();
    _authCubit = AdminAuthCubit(_authRepository);
  }

  @override
  void dispose() {
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _authRepository),
        RepositoryProvider.value(value: _eventRepository),
        RepositoryProvider.value(value: _journalRepository),
        RepositoryProvider.value(value: _participantRepository),
        RepositoryProvider.value(value: _assetLibraryRepository),
        RepositoryProvider.value(value: _questLibraryRepository),
      ],
      child: BlocProvider.value(
        value: _authCubit,
        child: MaterialApp(
          title: 'Expeditioneer Admin Console',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: BlocBuilder<AdminAuthCubit, AdminAuthState>(
            builder: (context, state) {
              return switch (state.status) {
                AdminAuthStatus.unknown => const _SplashScreen(),
                AdminAuthStatus.unauthenticated => const LoginScreen(),
                AdminAuthStatus.authenticated => const AdminShellScreen(),
              };
            },
          ),
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
