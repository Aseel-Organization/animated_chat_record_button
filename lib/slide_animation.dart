import 'package:flutter/material.dart';

class StaggeredSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final SlideDirection direction;

  const StaggeredSlideIn({
    super.key,
    required this.child,
    this.delay =
        const Duration(milliseconds: 100), // Delay before animation starts
    this.duration = const Duration(milliseconds: 500),
    required this.direction, // Animation duration
  });

  @override
  State createState() => _StaggeredSlideInState();
}

class _StaggeredSlideInState extends State<StaggeredSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _slideAnimation = Tween<Offset>(
      begin: slideOffset, // Start off-screen (right)
      end: Offset.zero, // End at normal position
    ).animate(CurvedAnimation(
        parent: _controller, curve: Curves.easeInOutCubicEmphasized));

    // Start animation with a delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset get slideOffset {
    switch (widget.direction) {
      case SlideDirection.end:
        return const Offset(1, 0);
      case SlideDirection.start:
        return const Offset(-1, 0);
      case SlideDirection.top:
        return const Offset(0, -1);
      case SlideDirection.bottom:
        return const Offset(0, 2);
    }
  }
}

enum SlideDirection {
  end,
  start,
  top,
  bottom,
}
