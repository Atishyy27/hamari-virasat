import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../theme.dart';
import 'ritual_detail_screen.dart';
import 'rituals_screen.dart';
import 'ui.dart';

/// Every family recipe, grouped under the ritual it belongs to. Read only: a recipe is
/// added and edited inside its ritual, so tapping one opens that ritual.
class RecipesScreen extends StatefulWidget {
  final AppUser user;
  const RecipesScreen({super.key, required this.user});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  List<Ritual> _rituals = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rituals = await guard(context, () => repo.listRituals());
    if (!mounted) return;
    setState(() {
      _rituals = rituals ?? _rituals;
      _loading = false;
    });
  }

  Future<void> _push(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final withRecipes = _rituals.where((r) => r.recipes.isNotEmpty).toList();
    final children = <Widget>[];
    if (_loading) {
      children.add(const Padding(padding: EdgeInsets.only(top: 80), child: Loading()));
    } else if (withRecipes.isEmpty) {
      children.add(
        EmptyState(
          icon: Icons.soup_kitchen_outlined,
          title: 'No recipes yet',
          line: 'Recipes live inside the ritual they are cooked for. Open a ritual and add its prasad and dishes.',
          action: FilledButton(
            onPressed: () => _push(RitualsScreen(user: widget.user)),
            child: const Text('Go to rituals'),
          ),
        ),
      );
    } else {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
          child: Text(
            'Each recipe belongs to a ritual. Tap one to open it there.',
            style: body(13.5, color: kMuted).copyWith(height: 1.4),
          ),
        ),
      );
      var index = 0;
      for (final ritual in withRecipes) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((ritual.category.isEmpty ? 'Ritual' : ritual.category).toUpperCase(), style: eyebrow()),
                const SizedBox(height: 4),
                Text(ritual.title.isEmpty ? '(untitled)' : ritual.title, style: display(19)),
              ],
            ),
          ),
        );
        for (final recipe in ritual.recipes) {
          children.add(
            FadeSlideIn(
              key: ValueKey('recipe-${recipe.id}'),
              index: index++,
              child: SoftCard(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                onTap: () => _push(RitualDetailScreen(user: widget.user, ritualId: ritual.id)),
                child: Row(
                  children: [
                    const IconBadge(Icons.soup_kitchen_outlined, size: 46, background: Color(0xFFF1DFC2)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(recipe.name, style: body(15.5, weight: 600)),
                          if (recipe.ingredients.trim().isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              recipe.ingredients.replaceAll('\n', ', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: body(12.5, color: kMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: kMuted),
                  ],
                ),
              ),
            ),
          );
        }
      }
    }
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Recipes', back: true),
            Expanded(
              child: RefreshIndicator(
                color: kMaroon,
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 28),
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
