import 'package:flutter/material.dart';

class DatePicker extends ChangeNotifier {
  DateTime? _dateTime = DateTime.now();
  DateTime get dateTime => _dateTime!;

  showCalendar(context) {
    showDatePicker(
      context: context,
      initialDate: _dateTime!,
      firstDate: DateTime(2021),
      lastDate: DateTime(2050),
    ).then((value) {
      value != null ? _dateTime = value : _dateTime = DateTime.now();
      notifyListeners();
    });
  }
}
