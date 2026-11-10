import 'package:flutter/material.dart';
import '../data/demo_images.dart';
import '../utils/app_colors.dart';

class CollectionCard extends StatefulWidget {
  final String title;
  final List<Color> colors;
  final IconData icon;
  final String? assetPath;
  final bool centered;
  final VoidCallback onTap;
  const CollectionCard({super.key, required this.title, required this.colors,
    required this.icon, required this.onTap, this.assetPath, this.centered = false});
  @override
  State<CollectionCard> createState() => _CollectionCardState();
}

class _CollectionCardState extends State<CollectionCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final url = DemoImages.collections[widget.title];
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? .985 : 1,
        duration: const Duration(milliseconds: 170),
        child: Material(
          color: widget.colors.first,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: SizedBox(
              height: 285,
              child: Stack(fit: StackFit.expand, children: [
                if (widget.assetPath != null)
                  Image.asset(widget.assetPath!, fit: BoxFit.cover)
                else if (url != null)
                  Image.network(url, fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => _fallback())
                else
                  _fallback(),
                const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xB8000000)],
                ))),
                Positioned(left: 22, right: 22, bottom: 24, child: Row(children: [
                  Expanded(child: Text(widget.title.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 27,
                      fontWeight: FontWeight.w900, letterSpacing: 1.2))),
                  Container(padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(color: AppColors.acid,
                      borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.arrow_outward_rounded, color: AppColors.textDark)),
                ])),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallback() => Container(
    decoration: BoxDecoration(gradient: LinearGradient(colors: widget.colors)),
    child: Center(child: Icon(widget.icon, size: 110, color: Colors.white54)),
  );
}
