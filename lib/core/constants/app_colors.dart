import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF0F172A); // Deep Navy Slate
  static const Color primaryLight = Color(0xFF1E293B);
  static const Color secondary = Color(0xFFD97706); // Warm Amber Accent
  static const Color secondaryLight = Color(0xFFF59E0B);
  
  // Backgrounds
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  
  static const Color backgroundDark = Color(0xFF020617);
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color cardDark = Color(0xFF1E293B);

  // Status Colors
  static const Color received = Color(0xFF3B82F6); // Blue
  static const Color inspection = Color(0xFF8B5CF6); // Purple
  static const Color approved = Color(0xFF06B6D4); // Cyan
  static const Color production = Color(0xFFF59E0B); // Amber
  static const Color coldChamber = Color(0xFF0284C7); // Light Blue
  static const Color qc = Color(0xFFEC4899); // Pink
  static const Color ready = Color(0xFF10B981); // Emerald Green
  static const Color delivered = Color(0xFF059669); // Dark Green
  static const Color rejected = Color(0xFFEF4444); // Red
  static const Color scrap = Color(0xFF6B7280); // Gray
  static const Color hold = Color(0xFFDC2626); // Dark Red

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Borders & Dividers
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);

  static Color getStatusColor(String status) {
    switch (status.trim()) {
      case 'Received':
        return received;
      case 'Inspection':
        return inspection;
      case 'Approved':
        return approved;
      case 'Production':
        return production;
      case 'Cold Chamber':
        return coldChamber;
      case 'QC':
        return qc;
      case 'Ready':
        return ready;
      case 'Delivered':
        return delivered;
      case 'Rejected':
        return rejected;
      case 'Scrap':
        return scrap;
      case 'Hold':
        return hold;
      default:
        return primary;
    }
  }
}
