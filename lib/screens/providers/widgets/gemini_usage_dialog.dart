import 'package:flutter/material.dart';

import '../../../services/api_client.dart';

class GeminiUsageDialog extends StatefulWidget {
  const GeminiUsageDialog({super.key, required this.providerId});

  final String providerId;

  @override
  State<GeminiUsageDialog> createState() => _GeminiUsageDialogState();
}

class _GeminiUsageDialogState extends State<GeminiUsageDialog> {
  final _client = ApiClient();
  late final _usage = _client.get(
    '/providers/${widget.providerId}/gemini-usage',
  );

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Token Gemini đã dùng'),
      scrollable: true,
      content: SizedBox(
        width: 420,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _usage,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(snapshot.error.toString());
            }
            final usage = snapshot.data;
            if (usage == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final metrics = (usage['metrics'] as List)
                .cast<Map<String, dynamic>>();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (usage['latestCall'] == true) ...[
                  const Text('Lượt gọi Gemini API vừa nhập từ PowerShell'),
                  Text('Model: ${usage['model']}'),
                ] else if (usage['snapshotDate'] case final String date) ...[
                  Text(
                    'Google AI Studio · ${date.split('-').reversed.join('/')} (UTC−8)',
                  ),
                  Text('Số liệu đã ghi nhận · ${usage['project']}'),
                ] else
                  Text('28 ngày gần nhất · ${usage['project']}'),
                for (final metric in metrics) ...[
                  const SizedBox(height: 16),
                  Text(
                    metric['label'] as String,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (metric['error'] case final String error) Text(error),
                  if (metric['total'] case final String total)
                    Text(
                      usage['latestCall'] == true
                          ? _formatTokens(total)
                          : 'Tổng: ${_formatTokens(total)}',
                    ),
                  if (metric['error'] == null &&
                      metric['total'] == null &&
                      (metric['rows'] as List).isEmpty)
                    const Text('Không có dữ liệu trong khoảng này.'),
                  for (final row
                      in (metric['rows'] as List).cast<Map<String, dynamic>>())
                    Text(
                      '${row['model']}: ${_formatTokens(row['tokens'] as String)}',
                    ),
                ],
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }

  String _formatTokens(String count) =>
      count.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
}
