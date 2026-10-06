import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

extension LocalizationX on BuildContext {
  String text(String key) => key.tr();
}
