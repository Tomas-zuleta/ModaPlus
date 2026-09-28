import 'package:flutter/material.dart';

class CartFlyAnimation {
  static final GlobalKey cartTargetKey = GlobalKey();

  static void play(
    BuildContext context, {
    required GlobalKey sourceKey,
    GlobalKey? targetKey,
    required Widget child,
    Duration duration = const Duration(milliseconds: 700),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final sourceContext = sourceKey.currentContext;
    final targetContext = (targetKey ?? cartTargetKey).currentContext;

    if (sourceContext == null) return;

    final sourceBox = sourceContext.findRenderObject() as RenderBox?;
    final targetBox = targetContext?.findRenderObject() as RenderBox?;

    if (sourceBox == null) return;

    final sourcePosition = sourceBox.localToGlobal(
      sourceBox.size.center(Offset.zero),
    );
    final targetPosition = targetBox != null
        ? targetBox.localToGlobal(
            targetBox.size.center(Offset.zero) + const Offset(12, -8),
          )
        : sourcePosition + const Offset(0, -80);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return _FlyWidget(
          start: sourcePosition,
          end: targetPosition,
          duration: duration,
          child: child,
          onComplete: () => entry.remove(),
        );
      },
    );

    overlay.insert(entry);
  }
}

class _FlyWidget extends StatefulWidget {
  final Offset start;
  final Offset end;
  final Duration duration;
  final Widget child;
  final VoidCallback onComplete;

  const _FlyWidget({
    required this.start,
    required this.end,
    required this.duration,
    required this.child,
    required this.onComplete,
  });

  @override
  State<_FlyWidget> createState() => _FlyWidgetState();
}

class _FlyWidgetState extends State<_FlyWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _offset = Tween<Offset>(
      begin: widget.start,
      end: widget.end,
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_controller);
    _scale = Tween<double>(begin: 1.0, end: 0.45).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _opacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInQuad));

    _controller.forward().whenComplete(() {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, animationChild) {
        final translate = _offset.value;
        final x = translate.dx;
        final y = translate.dy;

        return Positioned(
          left: x,
          top: y,
          child: Transform.translate(
            offset: Offset(-30, -30),
            child: Transform.scale(
              scale: 1 - (1 - _scale.value) * 0.6,
              child: Opacity(opacity: _opacity.value, child: animationChild),
            ),
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1F4D3A),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
