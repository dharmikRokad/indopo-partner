import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class TextStyles {
  TextStyles._();

  static TextStyle get headingBold =>
      GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white);

  static TextStyle get headingSemiBold =>
      GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white);

  static TextStyle get bodyRegular =>
      GoogleFonts.poppins(fontWeight: FontWeight.normal, color: Colors.white);

  static TextStyle get bodyMedium =>
      GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.white);

  static TextStyle get labelRegular => GoogleFonts.poppins(
    fontWeight: FontWeight.normal,
    color: AppColors.textMuted,
  );
}
