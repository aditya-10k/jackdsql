import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:jackdsql/blocs/playground_bloc.dart';
import 'package:jackdsql/blocs/auth_bloc.dart';
import 'package:jackdsql/blocs/ai_hint_bloc.dart';
import 'package:jackdsql/theme.dart';

class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundConsoleTheme {
  static const Color background = Color(0xff090c10);
  static const Color border = Color(0xff30363d);
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  String _selectedProvider = 'GEMINI';
  final TextEditingController _sqlController = TextEditingController(
    text: '-- SQL Playground Sandbox\n'
        '-- Sandbox creates a temporary schema and runs multi-statement queries.\n'
        '-- Ensure the final query is a SELECT statement to preview rows.\n\n'
        'CREATE TABLE developers (\n'
        '  id INT PRIMARY KEY,\n'
        '  name VARCHAR(50),\n'
        '  language VARCHAR(30)\n'
        ');\n\n'
        'INSERT INTO developers VALUES\n'
        '  (1, \'Alice\', \'SQL\'),\n'
        '  (2, \'Bob\', \'Flutter\'),\n'
        '  (3, \'Charlie\', \'Java\');\n\n'
        'SELECT * FROM developers;',
  );

  @override
  void initState() {
    super.initState();
    // Reset bloc state when sandbox enters
    context.read<PlaygroundBloc>().add(const PlaygroundClearEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'SQL PLAYGROUND',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 14,
          ),
        ),
      ),
      body: BlocListener<PlaygroundBloc, PlaygroundState>(
        listener: (context, state) {
          if (state is PlaygroundError) {
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
            }
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Interactive Sandbox',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'A sandbox schema where you can run custom DDL and DML statements. Dropping databases or hacking the root config is blocked by the threat-model compiler.',
                style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              _buildTerminalEditor(),
              const SizedBox(height: 24),
              _buildResultPanel(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTerminalEditor() {
    return Container(
      decoration: BoxDecoration(
        color: _PlaygroundConsoleTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _PlaygroundConsoleTheme.border),
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
                const Icon(Icons.terminal, color: AppTheme.primaryColor, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'SANDBOX CONSOLE',
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
                const Spacer(),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.hardColor,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {
                    setState(() => _sqlController.text = '');
                    context.read<PlaygroundBloc>().add(const PlaygroundClearEvent());
                  },
                  icon: const Icon(Icons.clear, size: 14),
                  label: const Text('Clear', style: TextStyle(fontSize: 11, fontFamily: 'JetBrainsMono')),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _sqlController,
              maxLines: null,
              minLines: 8,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'JetBrainsMono',
                fontSize: 13,
                height: 1.4,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '-- Write custom SQL...',
                hintStyle: TextStyle(color: Colors.white24, fontFamily: 'JetBrainsMono'),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xff161b22),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(11)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final query = _sqlController.text.trim();
                    if (query.isNotEmpty) {
                      context.read<PlaygroundBloc>().add(PlaygroundRunSqlEvent(query));
                    }
                  },
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Execute SQL'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultPanel() {
    return BlocBuilder<PlaygroundBloc, PlaygroundState>(
      builder: (context, state) {
        if (state is PlaygroundLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }

        if (state is PlaygroundSuccess) {
          final res = state.result;
          if (res.error != null) {
            return _buildOutputError(res.error!);
          }

          final cols = res.columns ?? [];
          final rows = res.rows ?? [];

          if (cols.isEmpty) {
            return _buildOutputSuccessMessage('Query parsed and executed successfully without error.');
          }

          return _buildOutputTable(cols, rows);
        }

        if (state is PlaygroundError) {
          return _buildOutputError(state.message);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildOutputError(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.hardColor.withOpacity(0.08),
        border: Border.all(color: AppTheme.hardColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline, color: AppTheme.hardColor, size: 16),
              SizedBox(width: 8),
              Text(
                'EXECUTION REFUSED',
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
      decoration: BoxDecoration(
        color: _PlaygroundConsoleTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _PlaygroundConsoleTheme.border),
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
              'RESULT TABLE VIEW (${rows.length} rows loaded)',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontFamily: 'JetBrainsMono',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SingleChildScrollView(
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
        ],
      ),
    );
  }

  void _showAiHintBottomSheet() {
    final aiHintBloc = context.read<AiHintBloc>();
    aiHintBloc.add(AiHintRequestEvent(
      questionId: 'playground',
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
                                  'Stuck? Enqueue an async inference request. The AI will audit your current SQL syntax and stream helpful directions.',
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
                                          questionId: 'playground',
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
                                        questionId: 'playground',
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
}
