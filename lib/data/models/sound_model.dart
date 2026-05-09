import 'package:flutter/material.dart';

enum SoundCategory { nature, rain, meditation }

class SoundModel {
  final String id;
  final String name;
  final String remoteUrl;
  final IconData icon;
  final SoundCategory category;
  final bool isFree;
  double volume;
  String? localPath;

  SoundModel({
    required this.id,
    required this.name,
    required this.remoteUrl,
    required this.icon,
    this.category = SoundCategory.nature,
    this.isFree = true,
    this.volume = 0.5,
    this.localPath,
  });
}
