import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pixel_input.dart';

class LabeledPixelInput extends StatelessWidget {
  const LabeledPixelInput({
    super.key,
    required this.label,
    required this.controller,
    required this.sw,
    required this.topPadding,
    this.keyboardType,
    this.obscureText = false,
    this.errorText,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final double sw;
  final double topPadding;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final labelStyle = GoogleFonts.pixelifySans(
      color: Colors.black,
      fontSize: 32,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: sw * 0.1,
            right: sw * 0.1,
            top: topPadding,
          ),
          child: Text(label, style: labelStyle),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: sw * 0.1),
          child: PixelInput(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            errorText: errorText,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
