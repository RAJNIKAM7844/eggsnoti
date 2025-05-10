import 'package:flutter/material.dart';

class CustomBackground extends StatelessWidget {
  final Widget child;

  const CustomBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        Container(
          color: const Color(0xFFF5F5F5), // Solid background color
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: size.height * 0.2,
            decoration: const BoxDecoration(
              color: Color(0xFF0288D1), // Solid header color
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
          ),
        ),
        SafeArea(child: child),
      ],
    );
  }
}
