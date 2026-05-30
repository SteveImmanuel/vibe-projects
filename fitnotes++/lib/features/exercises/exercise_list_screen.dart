import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/util/dates.dart';

/// The exercise database / picker. Shows categories first (FitNotes-style),
/// drilling into a category's exercises; searching looks across the scope.
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
  String? _categoryName;

  void _openCategory(int id, String name) =>
      setState(() {
        _categoryId = id;
        _categoryName = name;
        _search = '';
      });

  void _backToCategories() => setState(() {
        _categoryId = null;
        _categoryName = null;
        _search = '';
      });

  @override
  Widget build(BuildContext context) {
    final inCategory = _categoryId != null;
    final searching = _search.trim().isNotEmpty;
    final showExercises = inCategory || searching;

    return PopScope(
      canPop: !inCategory,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToCategories();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: inCategory
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _backToCategories)
              : null,
          title: Text(inCategory
              ? _categoryName!
              : (widget.pickMode ? 'Choose Exercise' : 'All Exercises')),
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
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search exercises',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: showExercises ? _exerciseList() : _categoryList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryList() {
    final categories = ref.watch(categoriesProvider);
    return categories.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (cats) => ListView.separated(
        itemCount: cats.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final c = cats[i];
          return ListTile(
            leading: CircleAvatar(radius: 12, backgroundColor: Color(c.colorArgb)),
            title: Text(c.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openCategory(c.id, c.name),
          );
        },
      ),
    );
  }

  Widget _exerciseList() {
    final items = ref.watch(
        exerciseListProvider((search: _search, categoryId: _categoryId)));
    return items.when(
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
                  onTap: () => _onTapExercise(e.id),
                );
              },
            ),
    );
  }

  void _onTapExercise(int id) {
    final date = widget.date ?? Dates.today();
    if (widget.pickMode) {
      context.pushReplacement('/log/$id?date=$date');
    } else {
      context.push('/log/$id?date=$date');
    }
  }
}
