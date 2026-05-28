import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jackdsql/blocs/ai_hint_bloc.dart';
import 'package:jackdsql/theme.dart';

class ApiKeysScreen extends StatelessWidget {
  const ApiKeysScreen({super.key});

  static const List<String> _providers = ['GEMINI', 'GROQ'];

  static final Map<String, Map<String, dynamic>> _providerMeta = {
    'GEMINI': {
      'label': 'Google Gemini',
      'icon': Icons.auto_awesome,
      'color': const Color(0xFF4285F4),
      'hint': 'Paste your Gemini API key (starts with AIza...)',
    },
    'GROQ': {
      'label': 'Groq LLM',
      'icon': Icons.bolt,
      'color': const Color(0xFFF5820D),
      'hint': 'Paste your Groq API key (starts with gsk_...)',
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI Provider Keys',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: BlocBuilder<AiHintBloc, AiHintState>(
        builder: (context, state) {
          final keyMap = {for (var k in state.keys) k.provider.toUpperCase(): k};

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor.withAlpha(50)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Keys are stored securely on the server and used only to generate SQL hints on practice questions. They are masked after saving.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (state.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  ),
                )
              else ...[
                for (final provider in _providers)
                  _buildProviderCard(
                    context: context,
                    provider: provider,
                    keyInfo: keyMap[provider],
                    state: state,
                  ),
              ],

              if (state.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.hardColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.hardColor.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.hardColor, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.error!,
                          style: const TextStyle(
                            color: AppTheme.hardColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildProviderCard({
    required BuildContext context,
    required String provider,
    required dynamic keyInfo,
    required AiHintState state,
  }) {
    final meta = _providerMeta[provider]!;
    final Color color = meta['color'] as Color;
    final bool configured = keyInfo != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: configured ? color.withAlpha(80) : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(meta['icon'] as IconData, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta['label'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: configured ? AppTheme.primaryColor : Colors.white24,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          configured ? 'Configured' : 'Not configured',
                          style: TextStyle(
                            color: configured ? AppTheme.primaryColor : Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Masked key display
          if (configured) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, color: Colors.white38, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      keyInfo.keyMask.isNotEmpty
                          ? keyInfo.keyMask
                          : '••••••••••••••••••••••',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontFamily: 'JetBrainsMono',
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              if (!configured)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color.withAlpha(30),
                      foregroundColor: color,
                      side: BorderSide(color: color.withAlpha(100)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _showAddKeySheet(context, provider, meta),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Key', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              else ...[
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _showAddKeySheet(
                      context, provider, meta, isUpdate: true,
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Update'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.hardColor,
                      side: BorderSide(color: AppTheme.hardColor.withAlpha(80)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _showDeleteSheet(context, provider),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Remove'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showAddKeySheet(
    BuildContext context,
    String provider,
    Map<String, dynamic> meta, {
    bool isUpdate = false,
  }) {
    final controller = TextEditingController();
    final Color color = meta['color'] as Color;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(meta['icon'] as IconData, color: color, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    '${isUpdate ? 'Update' : 'Add'} ${meta['label']} Key',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                obscureText: true,
                autofocus: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'JetBrainsMono',
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: meta['hint'] as String,
                  hintStyle: const TextStyle(
                    color: Colors.white30,
                    fontFamily: 'JetBrainsMono',
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                  prefixIcon: const Icon(Icons.vpn_key, color: Colors.white38, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: color.withAlpha(80)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final key = controller.text.trim();
                    if (key.isNotEmpty) {
                      context.read<AiHintBloc>().add(
                            AiHintAddKeyEvent(
                              provider: provider,
                              apiKey: key,
                            ),
                          );
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    isUpdate ? 'Update Key' : 'Save Key',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteSheet(BuildContext context, String provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 24),
              const Icon(Icons.delete_outline, color: AppTheme.hardColor, size: 40),
              const SizedBox(height: 16),
              Text(
                'Remove $provider Key?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The key will be deleted from the server. You can add a new one at any time.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.hardColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        context
                            .read<AiHintBloc>()
                            .add(AiHintDeleteKeyEvent(provider));
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Remove',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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
