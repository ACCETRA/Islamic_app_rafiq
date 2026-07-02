import 'package:flutter/material.dart';

/// One primary destination in an [AdaptiveShell].
class ShellDestination {
  const ShellDestination({
    required this.icon,
    required this.label,
    required this.builder,
  });

  final IconData icon;
  final String label;
  final WidgetBuilder builder;
}

/// App shell that switches between a floating bottom [NavigationBar]
/// (narrow/mobile widths) and a side [NavigationRail] (tablet/desktop
/// widths), and only ever constructs a destination's widget the first
/// time it's selected — so screens with side effects in `initState`
/// (e.g. location permission requests) don't fire until the user
/// actually opens that tab.
class AdaptiveShell extends StatefulWidget {
  const AdaptiveShell({super.key, required this.destinations});

  final List<ShellDestination> destinations;

  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends State<AdaptiveShell> {
  static const double _railBreakpoint = 600;
  static const double _maxContentWidth = 760;

  int _selectedIndex = 0;
  late final List<Widget?> _builtPages =
      List<Widget?>.filled(widget.destinations.length, null);

  void _select(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    _builtPages[_selectedIndex] ??=
        widget.destinations[_selectedIndex].builder(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _railBreakpoint;

        final stack = IndexedStack(
          index: _selectedIndex,
          children: [
            for (var i = 0; i < widget.destinations.length; i++)
              _wrapContent(_builtPages[i] ?? const SizedBox.shrink(), isWide),
          ],
        );

        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _select,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final d in widget.destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: stack),
              ],
            ),
          );
        }

        return Scaffold(
          body: stack,
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: NavigationBar(
                  selectedIndex: _selectedIndex,
                  height: 72,
                  elevation: 0,
                  labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
                  onDestinationSelected: _select,
                  destinations: [
                    for (final d in widget.destinations)
                      NavigationDestination(icon: Icon(d.icon), label: d.label),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _wrapContent(Widget child, bool isWide) {
    if (!isWide) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: child,
      ),
    );
  }
}
