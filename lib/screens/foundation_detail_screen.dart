import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:jackdsql/blocs/ai_hint_bloc.dart';
import 'package:jackdsql/blocs/auth_bloc.dart';
import 'package:jackdsql/blocs/foundation_bloc.dart';
import 'package:jackdsql/blocs/user_bloc.dart';
import 'package:jackdsql/models/foundation_models.dart';
import 'package:jackdsql/theme.dart';

class FoundationDetailScreen extends StatefulWidget {
  const FoundationDetailScreen({super.key});

  @override
  State<FoundationDetailScreen> createState() => _FoundationDetailScreenState();
}

class _ConsoleTheme {
  static const Color background = Color(0xff090c10);
  static const Color border = Color(0xff30363d);
}

class _FoundationDetailScreenState extends State<FoundationDetailScreen> {
  final TextEditingController _sqlController = TextEditingController();
  bool _initialized = false;
  String _selectedTopTab = 'description';
  String _selectedProvider = 'GEMINI';
  String _topicId = '';
  Foundation? _foundationDetail;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _sqlController.addListener(_onSqlChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _sqlController.removeListener(_onSqlChanged);
    _sqlController.dispose();
    super.dispose();
  }

  void _onSqlChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted &&
          _topicId.isNotEmpty &&
          _foundationDetail != null &&
          _sqlController.text.trim().isNotEmpty) {
        context.read<FoundationBloc>().add(
          FoundationPreviewSqlEvent(
            topicId: _topicId,
            userSql: _sqlController.text,
          ),
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _topicId = ModalRoute.of(context)!.settings.arguments as String;
      context.read<FoundationBloc>().add(FoundationFetchDetailEvent(_topicId));
      _initialized = true;
    }
  }

  @override
  void reassemble() {
    // Called on hot reload — preserve _initialized to prevent re-fetching.
    // If we already have data, skip the network re-fetch on hot reload.
    super.reassemble();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: BlocConsumer<FoundationBloc, FoundationState>(
        listener: (context, state) {
          if (state is FoundationDetailLoaded) {
            setState(() {
              _foundationDetail = state.foundation;
              // Pre-seed query if empty and schema exists
              if (_sqlController.text.isEmpty &&
                  state.foundation.practiceTasks != null &&
                  state.foundation.practiceTasks!.isNotEmpty) {
                final task = state.foundation.practiceTasks!.first;
                final String firstTable = _getFirstTableName(
                  task.expectedSchemaSql,
                );
                _sqlController.text = firstTable.isNotEmpty
                    ? 'SELECT * FROM $firstTable;'
                    : 'SELECT * FROM ;';
              }
            });
          } else if (state is FoundationSubmitSuccess) {
            if (state.submit.isCorrect) {
              context.read<UserBloc>().add(const UserFetchOverviewEvent());
              context.read<FoundationBloc>().add(
                const FoundationFetchCatalogueEvent(),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Completed! Foundation lesson passed.', style: TextStyle(fontFamily: 'JetBrainsMono')),
                    ],
                  ),
                  backgroundColor: const Color(0xff238636),
                  duration: const Duration(seconds: 2),
                ),
              );
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted) Navigator.pop(context);
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Incorrect output. Review and retry.', style: TextStyle(fontFamily: 'JetBrainsMono')),
                    ],
                  ),
                  backgroundColor: AppTheme.hardColor.withOpacity(0.9),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } else if (state is FoundationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: const TextStyle(fontFamily: 'JetBrainsMono'),
                ),
                backgroundColor: AppTheme.hardColor.withOpacity(0.8),
              ),
            );
            if (state.message.contains('Session expired') ||
                state.message.contains('Unauthorized')) {
              context.read<AiHintBloc>().add(const AiHintDisconnectSseEvent());
              context.read<AuthBloc>().add(const AuthLogoutEvent());
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            } else if (_foundationDetail == null) {
              Navigator.pop(context);
            }
          }
        },
        builder: (context, state) {
          if (_foundationDetail == null) {
            return Scaffold(
              backgroundColor: AppTheme.surfaceColor,
              appBar: AppBar(title: const Text('Chapter Details')),
              body: const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            );
          }

          final detail = _foundationDetail!;
          final task =
              detail.practiceTasks != null && detail.practiceTasks!.isNotEmpty
              ? detail.practiceTasks!.first
              : null;

          return Scaffold(
            backgroundColor: AppTheme.surfaceColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'CHAPTER ${detail.chapter}',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              bottom: const TabBar(
                indicatorColor: AppTheme.primaryColor,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.white54,
                tabs: [
                  Tab(text: 'LEARN LESSON'),
                  Tab(text: 'PRACTICE TASK'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildLessonTab(detail.title, detail.content),
                _buildPracticeTab(task),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLessonTab(String title, String content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          MarkdownBody(
            data: content,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                .copyWith(
                  p: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  h1: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.8,
                  ),
                  h2: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.6,
                  ),
                  code: const TextStyle(
                    color: AppTheme.primaryColor,
                    backgroundColor: Colors.black38,
                    fontFamily: 'JetBrainsMono',
                    fontSize: 13,
                  ),
                  codeblockPadding: const EdgeInsets.all(12),
                  codeblockDecoration: BoxDecoration(
                    color: const Color(0xff090c10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPracticeTab(PracticeTask? task) {
    if (task == null) {
      return const Center(
        child: Text(
          'No SQL practice tasks configured for this chapter.',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Practice Challenge',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: _buildTopContainer(
                    task.taskDescription,
                    task.expectedSchemaSql,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSqlEditor(task),
                const SizedBox(height: 12),
                _buildResultsWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSqlEditor(PracticeTask task) {
    return Container(
      decoration: BoxDecoration(
        color: _ConsoleTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ConsoleTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: const BoxDecoration(
              color: Color(0xff161b22),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.terminal,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'SQL QUERY CONSOLE',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontFamily: 'JetBrainsMono',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(canvasColor: AppTheme.surfaceContainer),
                  child: DropdownButton<String>(
                    value: _selectedProvider,
                    dropdownColor: AppTheme.surfaceContainer,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontFamily: 'JetBrainsMono',
                      fontSize: 13,
                    ),
                    underline: const SizedBox.shrink(),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AppTheme.primaryColor,
                      size: 16,
                    ),
                    items: ['GEMINI', 'GROQ']
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedProvider = val);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.easyColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _showAiHintBottomSheet(task),
                  icon: const Icon(Icons.psychology, size: 14),
                  label: const Text('AI Hint', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _sqlController,
              maxLines: null,
              minLines: 5,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'JetBrainsMono',
                fontSize: 13,
                height: 1.4,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '-- Enter SQL query...',
                hintStyle: TextStyle(
                  color: Colors.white24,
                  fontFamily: 'JetBrainsMono',
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xff161b22),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(11)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.easyColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    if (task.solutionSql.isNotEmpty) {
                      _showSolutionBottomSheet(task.solutionSql);
                    }
                  },
                  icon: const Icon(Icons.lightbulb_outline, size: 14),
                  label: const Text('Solution', style: TextStyle(fontSize: 13)),
                ),
                Spacer(),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    context.read<FoundationBloc>().add(
                      FoundationPreviewSqlEvent(
                        topicId: _topicId,
                        userSql: _sqlController.text,
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow, size: 14),
                  label: const Text('Preview', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () {
                    context.read<FoundationBloc>().add(
                      FoundationSubmitSqlEvent(
                        topicId: _topicId,
                        userSql: _sqlController.text,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check, size: 12),
                  label: const Text(
                    'Submit',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsWidget() {
    return BlocBuilder<FoundationBloc, FoundationState>(
      buildWhen: (previous, current) =>
          current is FoundationPreviewSuccess ||
          current is FoundationSubmitSuccess ||
          current is FoundationPreviewLoading ||
          current is FoundationSubmitLoading ||
          current is FoundationError,
      builder: (context, state) {
        if (state is FoundationSubmitLoading || state is FoundationPreviewLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }

        if (state is FoundationPreviewSuccess) {
          final res = state.preview;
          if (res.error != null) {
            return _buildOutputError(res.error!);
          }

          final cols = res.columns ?? [];
          final rows = res.rows ?? [];

          if (cols.isEmpty) {
            return _buildOutputSuccessMessage(
              'Query executed successfully but returned no columns.',
            );
          }

          return _buildOutputTable(cols, rows);
        }

        if (state is FoundationSubmitSuccess) {
          final isCorrect = state.submit.isCorrect;
          if (isCorrect) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.primaryColor,
                    size: 40,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COMPLETED',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Correct answer! Foundation lesson completed successfully.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.hardColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.hardColor),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.cancel_outlined,
                    color: AppTheme.hardColor,
                    size: 40,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INCORRECT OUTPUT',
                          style: TextStyle(
                            color: AppTheme.hardColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your query ran but did not yield correct results. Review the chapter concepts and retry.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        }

        if (state is FoundationError) {
          return _buildOutputError(state.message);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildOutputError(String error) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.hardColor.withOpacity(0.08),
        border: Border.all(color: AppTheme.hardColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error_outline, color: AppTheme.hardColor, size: 16),
                SizedBox(width: 8),
                Text(
                  'SYNTAX ERROR',
                  style: TextStyle(
                    color: AppTheme.hardColor,
                    fontSize: 11,
                    fontFamily: 'JetBrainsMono',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontFamily: 'JetBrainsMono',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputSuccessMessage(String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        msg,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontFamily: 'JetBrainsMono',
        ),
      ),
    );
  }

  Widget _buildOutputTable(List<String> cols, List<Map<String, dynamic>> rows) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: _ConsoleTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ConsoleTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xff161b22),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Text(
              'OUTPUT VIEW (${rows.length} rows returned)',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontFamily: 'JetBrainsMono',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xff161b22),
                  ),
                  columns: cols
                      .map(
                        (col) => DataColumn(
                          label: Text(
                            col,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontFamily: 'JetBrainsMono',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  rows: rows
                      .map(
                        (row) => DataRow(
                          cells: cols
                              .map(
                                (col) => DataCell(
                                  Text(
                                    row[col]?.toString() ?? 'NULL',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFirstTableName(String schemaSql) {
    try {
      final reg = RegExp(r'CREATE\s+TABLE\s+(\w+)', caseSensitive: false);
      final match = reg.firstMatch(schemaSql);
      if (match != null && match.groupCount >= 1) {
        return match.group(1)!;
      }
    } catch (_) {}
    return '';
  }

  void _showSolutionBottomSheet(String solution) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MODEL SOLUTION',
                    style: TextStyle(
                      color: AppTheme.easyColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xff090c10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  solution,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontFamily: 'JetBrainsMono',
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _sqlController.text = solution;
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Insert into Console'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopContainer(String description, String schemaSql) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ChoiceChip(
              label: Center(child: const Text('Problem Description')),
              selected: _selectedTopTab == 'description',
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedTopTab = 'description');
                }
              },
              selectedColor: AppTheme.primaryColor.withOpacity(0.15),
              backgroundColor: Colors.transparent,
              labelStyle: TextStyle(
                color: _selectedTopTab == 'description'
                    ? AppTheme.primaryColor
                    : Colors.white60,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              side: BorderSide(
                color: _selectedTopTab == 'description'
                    ? AppTheme.primaryColor
                    : Colors.white24,
              ),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Database Schema'),
              selected: _selectedTopTab == 'schema',
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedTopTab = 'schema');
                }
              },
              selectedColor: AppTheme.easyColor.withOpacity(0.15),
              backgroundColor: Colors.transparent,
              labelStyle: TextStyle(
                color: _selectedTopTab == 'schema'
                    ? AppTheme.easyColor
                    : Colors.white60,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              side: BorderSide(
                color: _selectedTopTab == 'schema'
                    ? AppTheme.easyColor
                    : Colors.white24,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _selectedTopTab == 'description'
              ? Container(
                  key: const ValueKey('desc'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: MarkdownBody(
                    data: description,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                        .copyWith(
                          p: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                  ),
                )
              : Container(
                  key: const ValueKey('schema'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xff090c10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    schemaSql,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'JetBrainsMono',
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  void _showAiHintBottomSheet(PracticeTask task) {
    final aiHintBloc = context.read<AiHintBloc>();
    aiHintBloc.add(
      AiHintRequestEvent(
        questionId: task.id,
        provider: _selectedProvider,
        sqlCode: _sqlController.text,
      ),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainer,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return BlocProvider.value(
          value: aiHintBloc,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              top: 24,
              left: 24,
              right: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            color: AppTheme.easyColor,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'AI CO-PILOT ASSISTANCE',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white60,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: BlocBuilder<AiHintBloc, AiHintState>(
                        builder: (context, state) {
                          final lastId = state.lastRequestId;
                          final hintContent = lastId != null
                              ? (state.activeHints[lastId] ?? '')
                              : '';
                          final isStreaming = state.isStreaming;

                          if (isStreaming && hintContent.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            );
                          }

                          if (hintContent.isEmpty &&
                              state.streamingError == null) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Stuck? Enqueue an async inference request. The AI will audit your current SQL syntax and stream helpful schema directions.',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white10,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    context.read<AiHintBloc>().add(
                                      AiHintRequestEvent(
                                        questionId: task.id,
                                        provider: _selectedProvider,
                                        sqlCode: _sqlController.text,
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.psychology,
                                    size: 16,
                                    color: AppTheme.easyColor,
                                  ),
                                  label: const Text('Request Co-Pilot Hint'),
                                ),
                              ],
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (state.streamingError != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Text(
                                    'Streaming failure: ${state.streamingError}',
                                    style: const TextStyle(
                                      color: AppTheme.hardColor,
                                      fontSize: 12,
                                      fontFamily: 'JetBrainsMono',
                                    ),
                                  ),
                                ),
                              if (hintContent.isNotEmpty)
                                MarkdownBody(
                                  data: hintContent,
                                  styleSheet:
                                      MarkdownStyleSheet.fromTheme(
                                        Theme.of(context),
                                      ).copyWith(
                                        p: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                        code: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          backgroundColor: Colors.black26,
                                          fontFamily: 'JetBrainsMono',
                                          fontSize: 12,
                                        ),
                                        codeblockPadding: const EdgeInsets.all(
                                          12,
                                        ),
                                        codeblockDecoration: BoxDecoration(
                                          color: const Color(0xff090c10),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.white10,
                                          ),
                                        ),
                                      ),
                                ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryColor,
                                  side: const BorderSide(
                                    color: AppTheme.primaryColor,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  context.read<AiHintBloc>().add(
                                    AiHintRequestEvent(
                                      questionId: task.id,
                                      provider: _selectedProvider,
                                      sqlCode: _sqlController.text,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Request Another Hint'),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
