import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:jackdsql/blocs/question_bloc.dart';
import 'package:jackdsql/blocs/ai_hint_bloc.dart';
import 'package:jackdsql/blocs/auth_bloc.dart';
import 'package:jackdsql/models/question_models.dart';
import 'package:jackdsql/theme.dart';
import 'package:jackdsql/blocs/user_bloc.dart';

class QuestionDetailScreen extends StatefulWidget {
  const QuestionDetailScreen({super.key});

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _DashboardConsoleTheme {
  static const Color background = Color(0xff090c10);
  static const Color border = Color(0xff30363d);
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  final TextEditingController _sqlController = TextEditingController();
  String _selectedProvider = 'GEMINI';
  bool _isBookmarked = false;
  bool _initialized = false;
  String _selectedTopTab = 'description';
  String _questionId = '';
  QuestionDetail? _questionDetail;
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
      if (mounted && _questionId.isNotEmpty && _questionDetail != null && _sqlController.text.trim().isNotEmpty) {
        context.read<QuestionBloc>().add(QuestionPreviewEvent(
              questionId: _questionId,
              userSql: _sqlController.text,
            ));
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _questionId = ModalRoute.of(context)!.settings.arguments as String;
      context.read<QuestionBloc>().add(QuestionFetchDetailEvent(questionId: _questionId));
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuestionBloc, QuestionState>(
      listener: (context, state) {
        if (state is QuestionDetailLoaded) {
          setState(() {
            _questionDetail = state.detail;
            _isBookmarked = state.detail.isBookmarked;
            // Pre-seed query input with a basic SELECT statement if empty
            if (_sqlController.text.isEmpty) {
              final String firstTable = _getFirstTableName(state.detail.question.schemaSql);
              _sqlController.text = firstTable.isNotEmpty 
                  ? 'SELECT * FROM $firstTable LIMIT 5;' 
                  : 'SELECT * FROM ;';
            }
          });
        } else if (state is QuestionBookmarkToggled) {
          setState(() {
            _isBookmarked = state.isBookmarked;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isBookmarked ? 'Question bookmarked.' : 'Bookmark removed.',
                style: const TextStyle(fontFamily: 'JetBrainsMono'),
              ),
              backgroundColor: AppTheme.surfaceContainer,
            ),
          );
        } else if (state is QuestionSubmitSuccess) {
          if (state.isCorrect) {
            context.read<UserBloc>().add(const UserFetchOverviewEvent());
            context.read<QuestionBloc>().add(const QuestionFetchGroupedEvent());
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Expanded(child: Text('Accepted! Problem solved correctly.', style: TextStyle(fontFamily: 'JetBrainsMono'))),
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
                    Text('Wrong answer. Try again.', style: TextStyle(fontFamily: 'JetBrainsMono')),
                  ],
                ),
                backgroundColor: AppTheme.hardColor.withOpacity(0.9),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else if (state is QuestionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: const TextStyle(fontFamily: 'JetBrainsMono'),
              ),
              backgroundColor: AppTheme.hardColor.withOpacity(0.8),
            ),
          );
          if (state.message.contains('Session expired') || state.message.contains('Unauthorized')) {
            context.read<AiHintBloc>().add(const AiHintDisconnectSseEvent());
            context.read<AuthBloc>().add(const AuthLogoutEvent());
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          } else if (_questionDetail == null) {
            Navigator.pop(context);
          }
        }
      },
      builder: (context, state) {
        if (_questionDetail == null) {
          return Scaffold(
            backgroundColor: AppTheme.surfaceColor,
            appBar: AppBar(title: const Text('Practice Question')),
            body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
          );
        }

        final question = _questionDetail!.question;

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
              question.domain.toUpperCase(),
              style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: _isBookmarked ? AppTheme.mediumColor : Colors.white,
                ),
                onPressed: () {
                  context.read<QuestionBloc>().add(QuestionBookmarkEvent(questionId: _questionId));
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      _buildDifficultyIndicator(question.difficulty),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          question.title,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: _buildTopContainer(question.description, question.schemaSql),
                ),
                const SizedBox(height: 16),
                _buildCodeEditor(),
                const SizedBox(height: 12),
                _buildResultsPanel(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );

      },
    );
  }

  Widget _buildDifficultyIndicator(String difficulty) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        color = AppTheme.easyColor;
        break;
      case 'medium':
        color = AppTheme.mediumColor;
        break;
      case 'hard':
        color = AppTheme.hardColor;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildCodeEditor() {
    return Container(
      decoration: BoxDecoration(
        color: _DashboardConsoleTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _DashboardConsoleTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Console Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: const BoxDecoration(
              color: Color(0xff161b22),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, color: AppTheme.primaryColor, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'SQL QUERY CONSOLE',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontFamily: 'JetBrainsMono',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Theme(
                  data: Theme.of(context).copyWith(
                    canvasColor: AppTheme.surfaceContainer,
                  ),
                  child: DropdownButton<String>(
                    value: _selectedProvider,
                    dropdownColor: AppTheme.surfaceContainer,
                    style: const TextStyle(color: AppTheme.primaryColor, fontFamily: 'JetBrainsMono', fontSize: 11),
                    underline: const SizedBox.shrink(),
                    icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor, size: 16),
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
                  onPressed: _showAiHintBottomSheet,
                  icon: const Icon(Icons.psychology, size: 14),
                  label: const Text('AI Hint', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
          // Input Fields
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _sqlController,
              maxLines: null,
              minLines: 4,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'JetBrainsMono',
                fontSize: 13,
                height: 1.4,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '-- Enter SQL query...',
                hintStyle: TextStyle(color: Colors.white24, fontFamily: 'JetBrainsMono'),
              ),
            ),
          ),
          // Command Buttons Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xff161b22),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(11)),
            ),
            child: Row(
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.easyColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    if (_questionDetail?.question.solutionSql.isNotEmpty ?? false) {
                      _showSolutionBottomSheet(_questionDetail!.question.solutionSql);
                    }
                  },
                  icon: const Icon(Icons.lightbulb_outline, size: 14),
                  label: const Text('Solution', style: TextStyle(fontSize: 11)),
                ),
                const Spacer(),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    context.read<QuestionBloc>().add(QuestionPreviewEvent(
                          questionId: _questionId,
                          userSql: _sqlController.text,
                        ));
                  },
                  icon: const Icon(Icons.play_arrow, size: 14),
                  label: const Text('Preview', style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () {
                    context.read<QuestionBloc>().add(QuestionSubmitEvent(
                          questionId: _questionId,
                          userSql: _sqlController.text,
                        ));
                  },
                  icon: const Icon(Icons.check, size: 12),
                  label: const Text('Submit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsPanel() {
    return BlocBuilder<QuestionBloc, QuestionState>(
      buildWhen: (previous, current) => 
        current is QuestionPreviewLoaded || 
        current is QuestionSubmitSuccess || 
        current is QuestionSubmitLoading ||
        current is QuestionPreviewLoading ||
        current is QuestionError,
      builder: (context, state) {
        if (state is QuestionSubmitLoading || state is QuestionPreviewLoading) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ));
        }

        if (state is QuestionPreviewLoaded) {
          final res = state.preview;
          if (res.error != null) {
            return _buildOutputError(res.error!);
          }

          final cols = res.columns ?? [];
          final rows = res.rows ?? [];

          if (cols.isEmpty) {
            return _buildOutputSuccessMessage('Query executed successfully but returned no columns.');
          }

          return _buildOutputTable(cols, rows);
        }

        if (state is QuestionSubmitSuccess) {
          if (state.isCorrect) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppTheme.primaryColor, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACCEPTED',
                          style: TextStyle(color: AppTheme.primaryColor, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your query solved the problem correctly! Progress has been logged.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  )
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
                  Icon(Icons.cancel_outlined, color: AppTheme.hardColor, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WRONG ANSWER',
                          style: TextStyle(color: AppTheme.hardColor, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your query did not return matching output. Verify logic and retry.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          }
        }

        if (state is QuestionError) {
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
                  'COMPILER ERROR',
                  style: TextStyle(color: AppTheme.hardColor, fontSize: 11, fontFamily: 'JetBrainsMono', fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'JetBrainsMono'),
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
        style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'JetBrainsMono'),
      ),
    );
  }

  Widget _buildOutputTable(List<String> cols, List<Map<String, dynamic>> rows) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: _DashboardConsoleTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _DashboardConsoleTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xff161b22),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Text(
              'OUTPUT VIEWER (${rows.length} rows returned)',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontFamily: 'JetBrainsMono',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Scrollable area
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xff161b22)),
                  columns: cols
                      .map((col) => DataColumn(
                            label: Text(
                              col,
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontFamily: 'JetBrainsMono',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ))
                      .toList(),
                  rows: rows
                      .map((row) => DataRow(
                            cells: cols
                                .map((col) => DataCell(Text(
                                      row[col]?.toString() ?? 'NULL',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontFamily: 'JetBrainsMono',
                                        fontSize: 12,
                                      ),
                                    )))
                                .toList(),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopContainer(String description, String schemaSql) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ChoiceChip(
              label: const Text('Problem Description'),
              selected: _selectedTopTab == 'description',
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedTopTab = 'description');
                }
              },
              selectedColor: AppTheme.primaryColor.withOpacity(0.15),
              backgroundColor: Colors.transparent,
              labelStyle: TextStyle(
                color: _selectedTopTab == 'description' ? AppTheme.primaryColor : Colors.white60,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              side: BorderSide(
                color: _selectedTopTab == 'description' ? AppTheme.primaryColor : Colors.white24,
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
                color: _selectedTopTab == 'schema' ? AppTheme.easyColor : Colors.white60,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              side: BorderSide(
                color: _selectedTopTab == 'schema' ? AppTheme.easyColor : Colors.white24,
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
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
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

  void _showAiHintBottomSheet() {
    final aiHintBloc = context.read<AiHintBloc>();
    aiHintBloc.add(AiHintRequestEvent(
      questionId: _questionId,
      provider: _selectedProvider,
      sqlCode: _sqlController.text,
    ));

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
                          Icon(Icons.psychology, color: AppTheme.easyColor, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'AI CO-PILOT ASSISTANCE',
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                        onPressed: () => Navigator.pop(modalContext),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: BlocBuilder<AiHintBloc, AiHintState>(
                        builder: (context, state) {
                          final lastId = state.lastRequestId;
                          final hintContent = lastId != null ? (state.activeHints[lastId] ?? '') : '';
                          final isStreaming = state.isStreaming;

                          if (isStreaming && hintContent.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: CircularProgressIndicator(color: AppTheme.primaryColor),
                              ),
                            );
                          }

                          if (hintContent.isEmpty && state.streamingError == null) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Stuck? Enqueue an async inference request. The AI will audit your current SQL syntax and stream helpful schema directions.',
                                  style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white10,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    context.read<AiHintBloc>().add(AiHintRequestEvent(
                                          questionId: _questionId,
                                          provider: _selectedProvider,
                                          sqlCode: _sqlController.text,
                                        ));
                                  },
                                  icon: const Icon(Icons.psychology, size: 16, color: AppTheme.easyColor),
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
                                    style: const TextStyle(color: AppTheme.hardColor, fontSize: 12, fontFamily: 'JetBrainsMono'),
                                  ),
                                ),
                              if (hintContent.isNotEmpty)
                                MarkdownBody(
                                  data: hintContent,
                                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                                    p: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                                    code: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      backgroundColor: Colors.black26,
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 12,
                                    ),
                                    codeblockPadding: const EdgeInsets.all(12),
                                    codeblockDecoration: BoxDecoration(
                                      color: const Color(0xff090c10),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryColor,
                                  side: const BorderSide(color: AppTheme.primaryColor),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  context.read<AiHintBloc>().add(AiHintRequestEvent(
                                        questionId: _questionId,
                                        provider: _selectedProvider,
                                        sqlCode: _sqlController.text,
                                      ));
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

  void _showSchemaBottomSheet(String questionTitle, String schemaSql) {
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'DATABASE SEED SCHEMA',
                    style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xff090c10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: SingleChildScrollView(
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
              ),
            ],
          ),
        );
      },
    );
  }

  String _getFirstTableName(String schemaSql) {
    // Utility to parse first table name from standard "CREATE TABLE name (" strings to seed editor input.
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
                  )
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
}
