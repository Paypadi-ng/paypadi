String formatDate(DateTime date) {
  final year = date.year.toString();
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '$year-$month-$day';
}

String getDayTime() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) {
    return 'morning';
  } else if (hour >= 12 && hour < 17) {
    return 'afternoon';
  } else {
    return 'evening';
  }
}

String getTransactionDate(DateTime? date) {
  if (date == null) return '';

  final localDate = date.toLocal();
  final months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final month = months[localDate.month - 1];
  final day = localDate.day.toString().padLeft(2, '0');
  final year = localDate.year.toString();
  final hour24 = localDate.hour;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final hour = hour12.toString().padLeft(2, '0');
  final minute = localDate.minute.toString().padLeft(2, '0');
  final meridiem = hour24 >= 12 ? 'PM' : 'AM';

  return '$month $day, $year, $hour:$minute $meridiem';
}
