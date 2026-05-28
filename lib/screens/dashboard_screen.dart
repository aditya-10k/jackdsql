import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jackdsql/blocs/ai_hint_bloc.dart';
import 'package:jackdsql/blocs/auth_bloc.dart';
import 'package:jackdsql/blocs/foundation_bloc.dart';
import 'package:jackdsql/blocs/question_bloc.dart';
import 'package:jackdsql/blocs/user_bloc.dart';
import 'package:jackdsql/models/question_models.dart';
import 'package:jackdsql/models/user_models.dart';
import 'package:jackdsql/models/foundation_models.dart';
import 'package:jackdsql/repositories/question_repository.dart';
import 'package:jackdsql/repositories/foundation_repository.dart';
import 'package:jackdsql/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  late DateTime _calendarMonth;

  // Cached data to survive bloc state transitions
  List<QuestionListing> _allQuestions = [];
  String _searchQuery = '';
  String _sortMode = 'Default';
  String _filterDifficulty = 'All';

  @override
  void initState() {
    super.initState();
    _calendarMonth = DateTime.now();
    context.read<QuestionBloc>().add(const QuestionFetchGroupedEvent());
    context.read<UserBloc>().add(const UserFetchOverviewEvent());
    context.read<FoundationBloc>().add(const FoundationFetchCatalogueEvent());
    _connectAiSse();
  }

  void _connectAiSse() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null && mounted) {
      context.read<AiHintBloc>().add(AiHintConnectSseEvent(token));
      context.read<AiHintBloc>().add(const AiHintFetchKeysEvent());
    }
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      context.read<UserBloc>().add(const UserFetchOverviewEvent());
    } else if (index == 1) {
      context.read<FoundationBloc>().add(const FoundationFetchCatalogueEvent());
    } else if (index == 2) {
      context.read<QuestionBloc>().add(const QuestionFetchGroupedEvent());
    } else if (index == 3) {
      context.read<UserBloc>().add(const UserFetchOverviewEvent());
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'JetBrains Mono'),
        ),
        backgroundColor: AppTheme.hardColor.withOpacity(0.8),
      ),
    );
  }

  void _handleSessionExpiredIfNeeded(BuildContext context, String message) {
    if (message.contains('Session expired') ||
        message.contains('Unauthorized')) {
      context.read<AiHintBloc>().add(const AiHintDisconnectSseEvent());
      context.read<AuthBloc>().add(const AuthLogoutEvent());
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<UserBloc, UserState>(
          listener: (context, state) {
            if (state is UserOverviewError) {
              _showErrorSnackBar(context, state.message);
              _handleSessionExpiredIfNeeded(context, state.message);
            }
          },
        ),
        BlocListener<FoundationBloc, FoundationState>(
          listener: (context, state) {
            if (state is FoundationError) {
              _showErrorSnackBar(context, state.message);
              _handleSessionExpiredIfNeeded(context, state.message);
            }
          },
        ),
        BlocListener<QuestionBloc, QuestionState>(
          listener: (context, state) {
            if (state is QuestionGroupedLoaded) {
              setState(() {
                _allQuestions = state.grouped.values
                    .expand((list) => list)
                    .toList();
              });
            } else if (state is QuestionError) {
              _showErrorSnackBar(context, state.message);
              _handleSessionExpiredIfNeeded(context, state.message);
            }
          },
        ),
        BlocListener<AiHintBloc, AiHintState>(
          listenWhen: (prev, curr) =>
              curr.error != prev.error ||
              curr.streamingError != prev.streamingError,
          listener: (context, state) {
            if (state.error != null) {
              _showErrorSnackBar(context, state.error!);
              _handleSessionExpiredIfNeeded(context, state.error!);
            }
            if (state.streamingError != null) {
              _showErrorSnackBar(context, state.streamingError!);
              _handleSessionExpiredIfNeeded(context, state.streamingError!);
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppTheme.surfaceColor,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildHomeTab(),
              _buildFoundationTab(),
              _buildQuestionsTab(),
              _buildProfileTab(),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primaryColor, width: 1.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Image.asset(
              "assets/database (1).png",
              width: 16,
              height: 16,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'jackdsql',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      elevation: 0,
      backgroundColor: AppTheme.surfaceColor,
      centerTitle: false,
      actions: [
        IconButton(
          tooltip: 'SQL Playground',
          onPressed: () => Navigator.of(context).pushNamed('/playground'),
          icon: const Icon(Icons.terminal, color: AppTheme.primaryColor),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onTabTapped,
      backgroundColor: AppTheme.surfaceContainer,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.white38,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school_outlined),
          activeIcon: Icon(Icons.school),
          label: 'Foundations',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.code_outlined),
          activeIcon: Icon(Icons.code),
          label: 'Practice',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  // ─── HOME TAB ─────────────────────────────────────────────────────────────

  // ─── HOME TAB ─────────────────────────────────────────────────────────────

  Widget _buildHomeTab() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final name = (authState is AuthAuthenticated)
            ? (authState.profile?.name ?? 'Developer')
            : 'Developer';
        return BlocBuilder<UserBloc, UserState>(
          builder: (context, userState) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                _buildHomeHeader(name),
                const SizedBox(height: 24),
                if (userState is UserLoading)
                  _buildHomeShimmer()
                else if (userState is UserOverviewLoaded) ...[
                  _buildHomeProgressMetrics(userState.overview.stats),
                  const SizedBox(height: 24),
                  _buildHomeCalendar(userState.overview.activityHistory),
                ] else if (userState is UserOverviewError)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'Failed to load metrics: ${userState.message}',
                      style: const TextStyle(
                        color: AppTheme.hardColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                _buildLabel('Quick Shortcuts'),
                const SizedBox(height: 12),
                _buildNavCard(
                  icon: Icons.school_rounded,
                  color: AppTheme.easyColor,
                  label: 'SQL Foundations',
                  subtitle:
                      'Step-by-step lessons from basics to advanced joins',
                  onTap: () => _onTabTapped(1),
                ),
                const SizedBox(height: 14),
                _buildNavCard(
                  icon: Icons.code_rounded,
                  color: AppTheme.primaryColor,
                  label: 'Practice Questions',
                  subtitle: 'Solve real-world SQL challenges by difficulty',
                  onTap: () => _onTabTapped(2),
                ),
                const SizedBox(height: 14),
                _buildNavCard(
                  icon: Icons.terminal_rounded,
                  color: AppTheme.mediumColor,
                  label: 'SQL Playground',
                  subtitle: 'Free sandbox to run any SQL against a live DB',
                  onTap: () => Navigator.of(context).pushNamed('/playground'),
                ),
                const SizedBox(height: 28),
                _buildSystemStatusRow(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHomeProgressMetrics(UserStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Completion Progress'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildProgressCard(
                title: 'Foundations',
                completed: stats.completedFoundations,
                total: stats.totalFoundations,
                color: AppTheme.easyColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildProgressCard(
                title: 'Practice',
                completed: stats.completedQuestions,
                total: stats.totalQuestions,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHomeCalendar(Map<String, List<String>> activityHistory) {
    final firstDay = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final daysInMonth = DateTime(
      _calendarMonth.year,
      _calendarMonth.month + 1,
      0,
    ).day;
    final offset = firstDay.weekday - 1;
    final totalItems = offset + daysInMonth;

    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final currentMonthName = monthNames[_calendarMonth.month - 1];
    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLabel('Activity History'),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white54,
                    ),
                    onPressed: () {
                      setState(() {
                        _calendarMonth = DateTime(
                          _calendarMonth.year,
                          _calendarMonth.month - 1,
                        );
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$currentMonthName ${_calendarMonth.year}',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontFamily: 'JetBrainsMono',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white54,
                    ),
                    onPressed: () {
                      setState(() {
                        _calendarMonth = DateTime(
                          _calendarMonth.year,
                          _calendarMonth.month + 1,
                        );
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      color: Colors.white30,
                      fontFamily: 'JetBrainsMono',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalItems,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              if (index < offset) {
                return const SizedBox.shrink();
              }

              final day = index - offset + 1;
              final dateKey =
                  '${_calendarMonth.year}-${_calendarMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
              final activityList = activityHistory[dateKey];
              final hasActivity =
                  activityList != null && activityList.isNotEmpty;

              return GestureDetector(
                onTap: hasActivity
                    ? () => _showActivityBottomSheet(dateKey, activityList)
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: hasActivity
                        ? AppTheme.primaryColor.withOpacity(0.12)
                        : Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasActivity
                          ? AppTheme.primaryColor.withOpacity(0.5)
                          : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          color: hasActivity ? Colors.white : Colors.white54,
                          fontWeight: hasActivity
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      if (hasActivity)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showActivityBottomSheet(String dateStr, List<String> questionIds) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ACTIVITY ON $dateStr',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontFamily: 'JetBrainsMono',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    IconButton(
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: questionIds.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _QuestionHistoryItem(
                        questionId: questionIds[index],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeHeader(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha(25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryColor.withAlpha(80)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'System Online',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 11,
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavCard({
    required IconData icon,
    required Color color,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatusRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: const Row(
        children: [
          Icon(Icons.dns_outlined, color: Colors.white30, size: 16),
          SizedBox(width: 10),
          Text(
            'API: localhost:8080  ·  DB: connected',
            style: TextStyle(
              color: Colors.white38,
              fontFamily: 'JetBrainsMono',
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ─── FOUNDATIONS TAB ───────────────────────────────────────────────────────

  Widget _buildHomeShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.05),
      highlightColor: Colors.white.withOpacity(0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: 100,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoundationShimmer() {
    return Column(
      children: [
        _buildSectionHeader('SQL Foundations', 'Loading chapters...'),
        Shimmer.fromColors(
          baseColor: Colors.white.withOpacity(0.05),
          highlightColor: Colors.white.withOpacity(0.12),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCatalogueProgressCard(int completed, int total) {
    final double pct = total > 0 ? (completed / total) : 0.0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overall Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                '${(pct * 100).toInt()}% ($completed/$total)',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getChapterIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('intro') || t.contains('basic')) {
      return Icons.info_outline;
    } else if (t.contains('join')) {
      return Icons.join_inner;
    } else if (t.contains('aggregate') || t.contains('sum') || t.contains('count') || t.contains('group') || t.contains('function')) {
      return Icons.functions;
    } else if (t.contains('filter') || t.contains('where') || t.contains('having')) {
      return Icons.filter_alt_outlined;
    } else if (t.contains('subquery') || t.contains('nest')) {
      return Icons.layers_outlined;
    } else if (t.contains('select') || t.contains('query')) {
      return Icons.search;
    } else if (t.contains('sort') || t.contains('order')) {
      return Icons.sort;
    } else if (t.contains('update') || t.contains('delete') || t.contains('insert') || t.contains('write')) {
      return Icons.edit_note;
    }
    return Icons.menu_book_outlined;
  }

  Widget _buildFoundationTab() {
    return BlocBuilder<FoundationBloc, FoundationState>(
      buildWhen: (prev, curr) =>
          curr is FoundationCatalogueLoaded ||
          curr is FoundationCatalogueLoading ||
          curr is FoundationError,
      builder: (context, state) {
        if (state is FoundationCatalogueLoaded) {
          final list = state.catalogue;
          if (list.isEmpty) {
            return _buildEmptyState(
              icon: Icons.school_outlined,
              message: 'No foundation chapters available yet.',
            );
          }
          final completedCount = list.where((c) => c.completed).length;
          final totalCount = list.length;
          return Column(
            children: [
              _buildSectionHeader('SQL Foundations', '${list.length} chapters'),
              _buildCatalogueProgressCard(completedCount, totalCount),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final chapter = list[index];
                    return _buildChapterCard(chapter, index);
                  },
                ),
              ),
            ],
          );
        }

        if (state is FoundationError) {
          return _buildErrorState(
            message: state.message,
            onRetry: () => context.read<FoundationBloc>().add(
              const FoundationFetchCatalogueEvent(),
            ),
          );
        }

        return _buildFoundationShimmer();
      },
    );
  }

  Widget _buildChapterCard(dynamic chapter, int index) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        '/foundation_detail',
        arguments: chapter.id,
      ).then((_) {
        if (context.mounted) {
          context.read<FoundationBloc>().add(const FoundationFetchCatalogueEvent());
          context.read<UserBloc>().add(const UserFetchOverviewEvent());
        }
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: chapter.completed
                ? AppTheme.primaryColor.withAlpha(80)
                : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: chapter.completed
                    ? AppTheme.primaryColor.withAlpha(25)
                    : Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  _getChapterIcon(chapter.title),
                  color: chapter.completed
                      ? AppTheme.primaryColor
                      : Colors.white54,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chapter ${chapter.chapter}',
                    style: TextStyle(
                      color: chapter.completed
                          ? AppTheme.primaryColor
                          : Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    chapter.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              chapter.completed ? Icons.check_circle : Icons.arrow_forward_ios,
              color: chapter.completed ? AppTheme.primaryColor : Colors.white24,
              size: chapter.completed ? 22 : 15,
            ),
          ],
        ),
      ),
    );
  }

  // ─── QUESTIONS TAB ────────────────────────────────────────────────────────

  Widget _buildQuestionsTab() {
    return Column(
      children: [
        _buildSectionHeader(
          'Practice Questions',
          '${_allQuestions.length} problems',
        ),
        _buildQuestionsFilters(),
        Expanded(child: _buildQuestionsContent()),
      ],
    );
  }

  Widget _buildQuestionsFilters() {
    return Container(
      color: AppTheme.surfaceColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: (val) =>
                setState(() => _searchQuery = val.toLowerCase()),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search questions...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.white38,
                size: 20,
              ),
              filled: true,
              fillColor: AppTheme.surfaceContainer,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Filter chips + sort dropdown
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Easy', 'Medium', 'Hard'].map((d) {
                      final selected = _filterDifficulty == d;
                      Color chipColor;
                      switch (d) {
                        case 'Easy':
                          chipColor = AppTheme.easyColor;
                          break;
                        case 'Medium':
                          chipColor = AppTheme.mediumColor;
                          break;
                        case 'Hard':
                          chipColor = AppTheme.hardColor;
                          break;
                        default:
                          chipColor = AppTheme.primaryColor;
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _filterDifficulty = d),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? chipColor.withAlpha(40)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? chipColor
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              d,
                              style: TextStyle(
                                color: selected ? chipColor : Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortMode,
                    dropdownColor: AppTheme.surfaceContainer,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                    isDense: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'Default',
                        child: Text('Default'),
                      ),
                      DropdownMenuItem(value: 'A→Z', child: Text('A→Z')),
                      DropdownMenuItem(value: 'Z→A', child: Text('Z→A')),
                      DropdownMenuItem(
                        value: 'Easy first',
                        child: Text('Easy first'),
                      ),
                      DropdownMenuItem(
                        value: 'Hard first',
                        child: Text('Hard first'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _sortMode = val);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsContent() {
    if (_allQuestions.isEmpty) {
      return BlocBuilder<QuestionBloc, QuestionState>(
        buildWhen: (prev, curr) =>
            curr is QuestionGroupedLoaded ||
            curr is QuestionGroupedLoading ||
            curr is QuestionError,
        builder: (context, state) {
          if (state is QuestionGroupedLoading || state is QuestionLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }
          if (state is QuestionError) {
            return _buildErrorState(
              message: state.message,
              onRetry: () => context.read<QuestionBloc>().add(
                const QuestionFetchGroupedEvent(),
              ),
            );
          }
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        },
      );
    }

    // Apply filters
    List<QuestionListing> filtered = _allQuestions.where((q) {
      final matchesSearch =
          _searchQuery.isEmpty || q.title.toLowerCase().contains(_searchQuery);
      final matchesDifficulty =
          _filterDifficulty == 'All' ||
          q.difficulty.toLowerCase() == _filterDifficulty.toLowerCase();
      return matchesSearch && matchesDifficulty;
    }).toList();

    // Apply sort
    switch (_sortMode) {
      case 'A→Z':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Z→A':
        filtered.sort((a, b) => b.title.compareTo(a.title));
        break;
      case 'Easy first':
        const order = {'easy': 0, 'medium': 1, 'hard': 2};
        filtered.sort(
          (a, b) => (order[a.difficulty.toLowerCase()] ?? 3).compareTo(
            order[b.difficulty.toLowerCase()] ?? 3,
          ),
        );
        break;
      case 'Hard first':
        const order = {'hard': 0, 'medium': 1, 'easy': 2};
        filtered.sort(
          (a, b) => (order[a.difficulty.toLowerCase()] ?? 3).compareTo(
            order[b.difficulty.toLowerCase()] ?? 3,
          ),
        );
        break;
    }

    if (filtered.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        message: 'No questions match your filters.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _QuestionCard(question: filtered[index]),
    );
  }

  // ─── PROFILE TAB ──────────────────────────────────────────────────────────

  Widget _buildProfileTab() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final profile = authState is AuthAuthenticated
            ? authState.profile
            : null;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // Avatar + info
            _buildProfileHeader(profile),
            const SizedBox(height: 24),
            // Progress section
            _buildProgressSection(),
            const SizedBox(height: 24),
            // API Keys card
            _buildApiKeysCard(),
            const SizedBox(height: 16),
            // Logout
            _buildLogoutButton(),
          ],
        );
      },
    );
  }

  Widget _buildProfileHeader(dynamic profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor.withAlpha(30),
              border: Border.all(
                color: AppTheme.primaryColor.withAlpha(100),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person,
              color: AppTheme.primaryColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.name ?? 'Developer',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile?.email ?? '',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        if (state is UserLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }

        if (state is UserOverviewLoaded) {
          final stats = state.overview.stats;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Progress Overview'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildProgressCard(
                      title: 'Foundations',
                      completed: stats.completedFoundations,
                      total: stats.totalFoundations,
                      color: AppTheme.easyColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildProgressCard(
                      title: 'Practice',
                      completed: stats.completedQuestions,
                      total: stats.totalQuestions,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildProgressCard({
    required String title,
    required int completed,
    required int total,
    required Color color,
  }) {
    final double pct = total > 0 ? (completed / total) : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: pct,
                  color: color,
                  backgroundColor: Colors.white10,
                  strokeWidth: 7,
                ),
              ),
              Text(
                '${(pct * 100).toInt()}%',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$completed / $total',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeysCard() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/api_keys'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.mediumColor.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.vpn_key_rounded,
                color: AppTheme.mediumColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Provider Keys',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Manage Gemini & Groq API keys for AI hints',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white30,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () {
        context.read<AiHintBloc>().add(const AiHintDisconnectSseEvent());
        context.read<AuthBloc>().add(const AuthLogoutEvent());
        Navigator.of(context).pushReplacementNamed('/login');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.hardColor.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.hardColor.withAlpha(60)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: AppTheme.hardColor, size: 18),
            SizedBox(width: 10),
            Text(
              'Sign Out',
              style: TextStyle(
                color: AppTheme.hardColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SHARED HELPERS ───────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white24, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.white38, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.hardColor,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceContainer,
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── QUESTION CARD ────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final QuestionListing question;

  const _QuestionCard({required this.question});

  @override
  Widget build(BuildContext context) {
    Color diffColor;
    switch (question.difficulty.toLowerCase()) {
      case 'easy':
        diffColor = AppTheme.easyColor;
        break;
      case 'medium':
        diffColor = AppTheme.mediumColor;
        break;
      case 'hard':
        diffColor = AppTheme.hardColor;
        break;
      default:
        diffColor = Colors.white38;
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        '/question_detail',
        arguments: question.id,
      ).then((_) {
        if (context.mounted) {
          context.read<QuestionBloc>().add(const QuestionFetchGroupedEvent());
          context.read<UserBloc>().add(const UserFetchOverviewEvent());
        }
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            // Difficulty dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: diffColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: diffColor.withAlpha(120),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: diffColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          question.difficulty.toUpperCase(),
                          style: TextStyle(
                            color: diffColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        question.domain,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (question.completed)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 18,
              )
            else if (question.bookmarked)
              const Icon(Icons.bookmark, color: AppTheme.mediumColor, size: 18)
            else
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white24,
                size: 14,
              ),
          ],
        ),
      ),
    );
  }
}

class _QuestionHistoryItem extends StatefulWidget {
  final String questionId;

  const _QuestionHistoryItem({required this.questionId});

  @override
  State<_QuestionHistoryItem> createState() => _QuestionHistoryItemState();
}

class _QuestionHistoryItemState extends State<_QuestionHistoryItem> {
  late Future<dynamic> _detailFuture;
  bool? _isBookmarkedLocal;

  @override
  void initState() {
    super.initState();
    final questionState = context.read<QuestionBloc>().state;
    final foundationState = context.read<FoundationBloc>().state;
    
    bool isQuestion = true;
    if (foundationState is FoundationCatalogueLoaded) {
      if (foundationState.catalogue.any((f) => f.id == widget.questionId)) {
        isQuestion = false;
      }
    } else if (questionState is QuestionGroupedLoaded) {
      bool foundInQuestions = false;
      for (final list in questionState.grouped.values) {
        if (list.any((q) => q.id == widget.questionId)) {
          foundInQuestions = true;
          break;
        }
      }
      isQuestion = foundInQuestions;
    }
    
    if (isQuestion) {
      _detailFuture = context.read<QuestionRepository>().getQuestionDetail(
        widget.questionId,
      );
    } else {
      _detailFuture = context.read<FoundationRepository>().getFoundationDetail(
        widget.questionId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: _detailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Shimmer.fromColors(
            baseColor: Colors.white.withOpacity(0.05),
            highlightColor: Colors.white.withOpacity(0.12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.03)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Row(
              children: [
                Icon(Icons.error_outline, color: AppTheme.hardColor, size: 16),
                SizedBox(width: 8),
                Text(
                  'Failed to load item detail',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data;
        if (data is Foundation) {
          return InkWell(
            onTap: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pushNamed(
                '/foundation_detail',
                arguments: data.id,
              ).then((_) {
                if (context.mounted) {
                  context.read<FoundationBloc>().add(const FoundationFetchCatalogueEvent());
                  context.read<UserBloc>().add(const UserFetchOverviewEvent());
                }
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.03)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.easyColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'FOUNDATION',
                      style: TextStyle(
                        color: AppTheme.easyColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${data.chapter}: ${data.title}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer placeholder for the bookmark button size
                ],
              ),
            ),
          );
        }

        final detail = data as QuestionDetail;
        _isBookmarkedLocal ??= detail.isBookmarked;

        Color diffColor;
        switch (detail.question.difficulty.toLowerCase()) {
          case 'easy':
            diffColor = AppTheme.easyColor;
            break;
          case 'medium':
            diffColor = AppTheme.mediumColor;
            break;
          case 'hard':
            diffColor = AppTheme.hardColor;
            break;
          default:
            diffColor = Colors.white38;
        }

        return InkWell(
          onTap: () {
            Navigator.of(context).pop(); // Close dialog
            Navigator.of(context).pushNamed(
              '/question_detail',
              arguments: detail.question.id,
            ).then((_) {
              if (context.mounted) {
                context.read<QuestionBloc>().add(const QuestionFetchGroupedEvent());
                context.read<UserBloc>().add(const UserFetchOverviewEvent());
              }
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.03)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: diffColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    detail.question.difficulty.toUpperCase(),
                    style: TextStyle(
                      color: diffColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    detail.question.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isBookmarkedLocal!
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: _isBookmarkedLocal!
                        ? AppTheme.mediumColor
                        : Colors.white30,
                    size: 20,
                  ),
                  onPressed: () async {
                    setState(() {
                      _isBookmarkedLocal = !_isBookmarkedLocal!;
                    });
                    try {
                      final status = await context
                          .read<QuestionRepository>()
                          .bookmarkQuestion(detail.question.id);
                      setState(() {
                        _isBookmarkedLocal = status;
                      });
                    } catch (_) {
                      setState(() {
                        _isBookmarkedLocal = !_isBookmarkedLocal!;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
