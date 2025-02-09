import 'package:flutter/material.dart';

class NPC {
  final String name;
  final String portraitPath;
  final List<String> dialogueOptions;
  final int playerNumber;
  double relationship; // -1.0 to 1.0, where -1 is hostile, 0 is neutral, 1 is friendly
  
  NPC({
    required this.name,
    required this.portraitPath,
    required this.dialogueOptions,
    required this.playerNumber,
    this.relationship = 0.0,
  });
} 