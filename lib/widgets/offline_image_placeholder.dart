import 'package:flutter/material.dart';

class OfflineImagePlaceholder extends StatelessWidget {
  final double iconSize;
  const OfflineImagePlaceholder({super.key, this.iconSize = 34});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, height: double.infinity,
    color: const Color(0xFF101B2D), alignment: Alignment.center,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.wifi_off_rounded, color: Colors.white54, size: iconSize),
      const SizedBox(height: 6),
      const Text('No Internet', textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500)),
    ]),
  );
}