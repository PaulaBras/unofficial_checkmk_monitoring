import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String labelText;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final void Function(String)? onChanged;
  final bool obscureText;
  final String initialValue;

  const CustomTextField({
    super.key,
    required this.labelText,
    required this.validator,
    required this.onSaved,
    required this.initialValue,
    this.onChanged,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(),
      ),
      validator: validator,
      onSaved: onSaved,
      onChanged: onChanged,
    );
  }
}
