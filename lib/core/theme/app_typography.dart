import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextStyle displayLarge(BuildContext context) => GoogleFonts.sora(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -1.0,
    color: AppColors.txt(context),
  );

  static TextStyle headingL(BuildContext context) => GoogleFonts.sora(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: AppColors.txt(context),
  );

  static TextStyle headingM(BuildContext context) => GoogleFonts.sora(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.txt(context),
  );

  static TextStyle headingS(BuildContext context) => GoogleFonts.sora(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: AppColors.txt(context),
  );

  static TextStyle bodyL(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.txt(context),
  );

  static TextStyle bodyM(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.txt(context),
  );

  static TextStyle bodyS(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.txtSec(context),
  );

  static TextStyle labelBold(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    color: AppColors.txt(context),
  );
}
