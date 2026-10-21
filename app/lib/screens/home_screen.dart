import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme.dart';
import 'add_memory_screen.dart';
import 'book_screen.dart';
import 'family_screen.dart';
import 'home_tab.dart';
import 'profile_screen.dart';

/// The signed-in shell: Home, Family, Capture (+), Book and Profile, as in the Figma bar.
class HomeScreen extends StatefulWidget {
  final AppUser user;
  final Future<void> Function() onSignOut;

  const HomeScreen({super.key, required this.user, required this.onSignOut});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 0 Home, 1 Family, 3 Book, 4 Profile. 2 is Capture, which opens a page instead.
  int _index = 0;

  // Bumped whenever data may have changed, so the visible tab is rebuilt and reloads.
  int _version = 0;

  void _go(int index) => setState(() {
        _index = index;
        _version++;
      });

  Future<void> _capture() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddMemoryScreen(user: widget.user)),
    );
    if (mounted) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) {
    final Widget tab;
    switch (_index) {
      case 1:
        tab = FamilyScreen(user: widget.user);
      case 3:
        tab = BookScreen(user: widget.user);
      case 4:
        tab = ProfileScreen(user: widget.user, onSignOut: widget.onSignOut, onOpenFamily: () => _go(1));
      default:
        tab = HomeTab(user: widget.user, onCapture: _capture, onOpenFamily: () => _go(1), onOpenBook: () => _go(3));
    }
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        bottom: false,
        child: KeyedSubtree(key: ValueKey('tab-$_index-$_version'), child: tab),
      ),
      bottomNavigationBar: _BottomBar(index: _index, onTap: _go, onCapture: _capture),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onCapture;
  const _BottomBar({required this.index, required this.onTap, required this.onCapture});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(top: BorderSide(color: kLine)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _item(0, Icons.home_outlined, 'Home'),
              _item(1, Icons.people_outline, 'Family'),
              Expanded(
                child: InkResponse(
                  onTap: onCapture,
                  radius: 44,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Raised above the bar, as in the design.
                      Transform.translate(
                        offset: const Offset(0, -14),
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: kMaroon,
                            shape: BoxShape.circle,
                            border: Border.all(color: kGold.withValues(alpha: 0.6)),
                            boxShadow: [
                              BoxShadow(
                                color: kMaroon.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 28),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -10),
                        child: Text('Capture', style: body(11.5, weight: 700, color: kMaroon)),
                      ),
                    ],
                  ),
                ),
              ),
              _item(3, Icons.menu_book_outlined, 'Book'),
              _item(4, Icons.person_outline, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int i, IconData icon, String label) {
    final selected = index == i;
    final color = selected ? kMaroon : kMuted;
    return Expanded(
      child: InkResponse(
        onTap: () => onTap(i),
        radius: 40,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 5),
              Text(label, style: body(11.5, weight: selected ? 700 : 500, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
