import 'package:intl/intl.dart';

extension NumberFormatting on num {
  String toFormattedNumber() {
    return NumberFormat.decimalPattern().format(this);
  }
}
