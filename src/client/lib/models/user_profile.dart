import 'dart:math';

import 'package:flutter/material.dart';

/// Вариант аватара: цвет одежды и символ (как выбор персонажа в прототипе).
class AvatarPreset {
  const AvatarPreset(this.shirt, this.emoji);

  final Color shirt;
  final String emoji;
}

const avatarPresets = <AvatarPreset>[
  AvatarPreset(Color(0xFF4F46E5), '🧑‍🎓'),
  AvatarPreset(Color(0xFF06B6D4), '👩‍🎓'),
  AvatarPreset(Color(0xFF16A34A), '🧔'),
  AvatarPreset(Color(0xFFE11D48), '👩'),
  AvatarPreset(Color(0xFFF59E0B), '👨‍🎓'),
  AvatarPreset(Color(0xFF7C3AED), '🧑'),
];

/// Профиль студента: имя, аватар и личные финансы в тенге за месяц.
class UserProfile {
  const UserProfile({
    required this.name,
    required this.avatarIndex,
    required this.income,
    required this.expenses,
    required this.savings,
    required this.debt,
  });

  final String name;
  final int avatarIndex;
  final int income;
  final int expenses;
  final int savings;
  final int debt;

  /// Свободный остаток в месяц: доход минус обязательные расходы, не ниже нуля.
  int get free => max(0, income - expenses);

  /// Цель резерва: три месяца обязательных расходов.
  int get reserveTarget => expenses * 3;

  AvatarPreset get avatar => avatarPresets[avatarIndex];
}
