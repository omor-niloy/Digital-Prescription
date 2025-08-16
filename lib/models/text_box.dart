import 'package:flutter/material.dart';

class TextBox {
  final String id;
  final TextEditingController controller;
  final Rect position;
  final String hintText;

  TextBox({
    required this.id,
    required this.controller,
    required this.position,
    this.hintText = '',
  });
}
