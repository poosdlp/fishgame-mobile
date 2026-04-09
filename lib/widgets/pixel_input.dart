import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PixelInput extends StatelessWidget {
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const PixelInput({
    super.key,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle =
        GoogleFonts.pixelifySans(fontSize: 16, color: Colors.black);

    final errorStyle =
        GoogleFonts.pixelifySans(fontSize: 14, color: Colors.black);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(3),
      color: const Color.fromARGB(255, 143, 97, 28),
      child: Container(
        padding: const EdgeInsets.all(3),
        color: const Color.fromARGB(255, 120, 85, 50),
        child: Container(
          color: const Color.fromARGB(235, 255, 255, 255),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: textStyle,
            onChanged: onChanged,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              errorText: errorText,
              errorStyle: errorStyle,
            ),
          ),
        ),
      ),
    );
  }
}
