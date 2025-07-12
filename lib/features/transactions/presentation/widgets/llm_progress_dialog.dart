import 'package:flutter/material.dart';

class LLMProgressDialog extends StatelessWidget {
  final int current;
  final int total;
  final String currentItem;

  const LLMProgressDialog({
    super.key,
    required this.current,
    required this.total,
    required this.currentItem,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : 0.0;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.psychology, color: Colors.blue),
          SizedBox(width: 8),
          Text('AI Analysis in Progress'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analyzing SMS messages with AI for better insights...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(
            '$current of $total messages processed',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Current: ${currentItem.length > 30 ? '${currentItem.substring(0, 30)}...' : currentItem}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hide'),
        ),
      ],
    );
  }
}

class SMSProgressIndicator extends StatelessWidget {
  final int current;
  final int total;
  final String currentItem;

  const SMSProgressIndicator({
    super.key,
    required this.current,
    required this.total,
    required this.currentItem,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : 0.0;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'AI Analysis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 8),
            Text(
              '$current of $total SMS messages processed',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (currentItem.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Analyzing: ${currentItem.length > 40 ? '${currentItem.substring(0, 40)}...' : currentItem}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
