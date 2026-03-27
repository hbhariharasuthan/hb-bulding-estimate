import 'package:flutter/material.dart';

class PageContainer extends StatelessWidget {
  const PageContainer({
    super.key,
    required this.child,
    this.maxWidth = 1180,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}
