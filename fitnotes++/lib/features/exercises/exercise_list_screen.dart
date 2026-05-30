import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/util/dates.dart';

/// The exercise database. Doubles as a picker (pickMode) when adding an
/// exercise to a workout.
class ExerciseListScreen extends ConsumerStatefulWidget {
  const ExerciseListScreen({super.key, this.pickMode = false, this.date});

  final bool pickMode;
  final String? date;

  @override
  ConsumerState<ExerciseListScreen> createState() =>
      _ExerciseListScreenState();
}

class _ExerciseListScreenState extends ConsumerState<ExerciseListScreen> {
  String _search = '';
  int? _categoryId;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(
        exerciseListProvider((search: _search, categoryId: _categoryId)));
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pickMode ? 'Choose Exercise' : 'All Exercises'),
        actions: [
          IconButton(
            tooltip: 'New exercise',
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/exercises/edit'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          SizedBox(
            height: 44,
            child: categories.maybeWhen(
              data: (cats) => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('All'),
                      selected: _categoryId == null,
                      onSelected: (_) => setState(() => _categoryId = null),
                    ),
                  ),
                  for (final c in cats)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: CircleAvatar(
                            radius: 6, backgroundColor: Color(c.colorArgb)),
                        label: Text(c.name),
                        selected: _categoryId == c.id,
                        onSelected: (_) => setState(() => _categoryId = c.id),
                      ),
                    ),
                ],
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: items.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (list) => list.isEmpty
                  ? const Center(child: Text('No exercises'))
                  : ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final e = list[i];
                        return ListTile(
                          leading: CircleAvatar(
                              radius: 8, backgroundColor: Color(e.colorArgb)),
                          title: Text(e.name),
                          subtitle: Text(e.workoutCount == 0
                              ? 'Never performed'
                              : '${e.workoutCount} workouts • last ${e.lastDate}'),
                          onTap: () => _onTap(e.id),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _onTap(int id) {
    final date = widget.date ?? Dates.today();
    if (widget.pickMode) {
      context.pushReplacement('/log/$id?date=$date');
    } else {
      context.push('/log/$id?date=$date');
    }
  }
}
