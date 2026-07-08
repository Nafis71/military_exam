import 'package:flutter/material.dart';

/// Staggered fade-and-slide entrance for a vertical list of sections.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.children,
    this.contentKey,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.duration = const Duration(milliseconds: 900),
  });

  final List<Widget> children;
  final Object? contentKey;
  final CrossAxisAlignment crossAxisAlignment;
  final Duration duration;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.forward();
  }

  @override
  void didUpdateWidget(StaggeredEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contentKey != oldWidget.contentKey) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Interval _intervalFor(int index) {
    final total = widget.children.length;
    if (total <= 1) {
      return const Interval(0.0, 1.0, curve: Curves.easeOutCubic);
    }

    final span = 0.85 / total;
    final start = index * span;
    final end = (start + span + 0.15).clamp(0.0, 1.0);
    return Interval(start, end, curve: Curves.easeOutCubic);
  }

  Widget _animatedChild(int index, Widget child) {
    final interval = _intervalFor(index);
    final opacity = CurvedAnimation(parent: _controller, curve: interval);
    final offset = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: interval));

    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(position: offset, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: widget.crossAxisAlignment,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _animatedChild(i, widget.children[i]),
      ],
    );
  }
}
