import 'package:flutter/material.dart';

class AuthFormButtons extends StatelessWidget {
  const AuthFormButtons({
    super.key,
    required this.sh,
    required this.sw,
    required this.isSubmitting,
    required this.onBack,
    required this.onSubmit,
  });

  final double sh;
  final double sw;
  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: sh * 0.08,
        left: sw * 0.1,
        right: sw * 0.1,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: isSubmitting ? null : onBack,
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: isSubmitting ? null : onSubmit,
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
