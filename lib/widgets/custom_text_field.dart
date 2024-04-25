import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String labelText;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final bool obscureText;

  const CustomTextField({
    super.key,
    required this.labelText,
    required this.validator,
    required this.onSaved,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
      ),
      validator: validator,
      onSaved: onSaved,
    );
  }
}