const _monthAbbrevs = [
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

/// e.g. "8 Mar" - matches the compact date style used on race cards/tables.
String shortDate(DateTime date) => '${date.day} ${_monthAbbrevs[date.month - 1]}';

const _weekdayAbbrevs = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// e.g. "Sat 25 Jul, 14:00 UTC" - for session schedule times, which unlike
/// race dates need the time-of-day shown too.
String shortDateTime(DateTime utc) {
  final weekday = _weekdayAbbrevs[utc.weekday - 1];
  final hour = utc.hour.toString().padLeft(2, '0');
  final minute = utc.minute.toString().padLeft(2, '0');
  return '$weekday ${shortDate(utc)}, $hour:$minute UTC';
}
