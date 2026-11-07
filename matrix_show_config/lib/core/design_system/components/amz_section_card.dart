import 'package:flutter/material.dart';
import '../spacing.dart';

class AmzSectionCard extends StatelessWidget {
  const AmzSectionCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(AmzSpacing.md), child: child),
  );
}