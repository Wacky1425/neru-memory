import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../widgets/common.dart';
import 'tag_results_page.dart';

class TagsPage extends StatelessWidget {
  const TagsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final counts = <String, int>{};

    void addAll(Iterable<List<String>> groups) {
      for (final tags in groups) {
        for (final raw in tags) {
          final tag = raw.trim();
          if (tag.isNotEmpty) counts[tag] = (counts[tag] ?? 0) + 1;
        }
      }
    }

    addAll(s.tasks.map((x) => x.tags));
    addAll(s.wants.map((x) => x.tags));
    addAll(s.futures.map((x) => x.tags));
    addAll(s.goals.map((x) => x.tags));

    final tags = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('タグ')),
      body: PageWrap(
        child: tags.isEmpty
            ? const Center(child: Text('タグはまだありません\n各項目の編集画面から追加できます', textAlign: TextAlign.center))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  Text('すべての項目をタグで横断できます', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in tags)
                        ActionChip(
                          avatar: const Icon(Icons.tag, size: 18),
                          label: Text('$tag  ${counts[tag]}'),
                          onPressed: () => openTagResults(context, tag),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
