import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';
import '../../widgets/common.dart';
import '../lists/editors.dart';

class TagResultsPage extends StatelessWidget {
  const TagResultsPage({super.key, required this.tag});
  final String tag;

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final tasks = s.tasks.where((x) => x.tags.contains(tag)).toList();
    final wants = s.wants.where((x) => x.tags.contains(tag)).toList();
    final futures = s.futures.where((x) => x.tags.contains(tag)).toList();
    final goals = s.goals.where((x) => x.tags.contains(tag)).toList();
    final total = tasks.length + wants.length + futures.length + goals.length;

    return Scaffold(
      appBar: AppBar(title: Text('#$tag')),
      body: PageWrap(
        child: total == 0
            ? const Center(child: Text('このタグの項目はありません'))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  Text('$total件', style: Theme.of(context).textTheme.labelLarge),
                  if (tasks.isNotEmpty) ...[
                    const SectionTitle('やること'),
                    for (final x in tasks)
                      Card(child: ListTile(
                        leading: Icon(x.completed ? Icons.check_circle : Icons.check_circle_outline),
                        title: Text(x.title),
                        subtitle: x.note.isEmpty ? null : Text(x.note, maxLines: 2, overflow: TextOverflow.ellipsis),
                        onTap: () => editTask(context, x),
                      )),
                  ],
                  if (wants.isNotEmpty) ...[
                    const SectionTitle('買いたい'),
                    for (final x in wants)
                      Card(child: ListTile(
                        leading: const Icon(Icons.shopping_bag_outlined),
                        title: Text(x.title),
                        subtitle: Text([if(x.budget != null) '¥${x.budget!.round()}', x.timing, x.waitingFor].where((e) => e.isNotEmpty).join(' · ')),
                        onTap: () => editWant(context, x),
                      )),
                  ],
                  if (futures.isNotEmpty) ...[
                    const SectionTitle('予定候補'),
                    for (final x in futures)
                      Card(child: ListTile(
                        leading: const Icon(Icons.push_pin_outlined),
                        title: Text(x.title),
                        subtitle: Text([x.timing, x.status.name].where((e) => e.isNotEmpty).join(' · ')),
                        onTap: () => editFuture(context, x),
                      )),
                  ],
                  if (goals.isNotEmpty) ...[
                    const SectionTitle('目標'),
                    for (final x in goals)
                      Card(child: ListTile(
                        leading: const Icon(Icons.flag_outlined),
                        title: Text(x.title),
                        subtitle: Text('${(x.progress * 100).round()}%${x.deadlineLabel.isEmpty ? '' : ' · ${x.deadlineLabel}'}'),
                      )),
                  ],
                ],
              ),
      ),
    );
  }
}

void openTagResults(BuildContext context, String tag) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => TagResultsPage(tag: tag)));
}
