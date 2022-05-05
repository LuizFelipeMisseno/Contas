import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFonts {
  static TextStyle title = GoogleFonts.poppins(
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.normal,
    fontSize: 24,
  );
  static TextStyle subtitle = GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.normal,
    fontSize: 20,
  );
  static TextStyle mainDescriptions = GoogleFonts.poppins(
    fontWeight: FontWeight.w500,
    fontStyle: FontStyle.normal,
    fontSize: 22,
  );
  static TextStyle normal = GoogleFonts.poppins(
    color: Colors.black,
    fontWeight: FontWeight.normal,
    fontStyle: FontStyle.normal,
    fontSize: 16,
  );
  static TextStyle description = GoogleFonts.poppins(
    color: Colors.black,
    fontWeight: FontWeight.normal,
    fontStyle: FontStyle.normal,
    fontSize: 14,
  );
  static TextStyle textField = GoogleFonts.poppins(
    color: Colors.black,
    fontWeight: FontWeight.normal,
    fontStyle: FontStyle.normal,
    fontSize: 18,
  );
  static TextStyle optionsSelected = GoogleFonts.poppins(
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.normal,
    fontSize: 20,
  );
  static TextStyle optionsUnselected = GoogleFonts.poppins(
    color: Colors.grey,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.normal,
    fontSize: 20,
  );
}
