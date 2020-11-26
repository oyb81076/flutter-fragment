// @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Last-Modified
const _WEEK_DAY = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
const _MONTH = [
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "May",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec"
];

String toUTC(DateTime date) {
  if (date == null) return null;
  if (!date.isUtc) date = date.toUtc();
  String dayName = _WEEK_DAY[date.weekday - 1];
  String day = date.day.toString().padLeft(2, '0');
  String month = _MONTH[date.month - 1];
  String year = date.year.toString().padLeft(4, '0');
  String hour = date.hour.toString().padLeft(2, '0');
  String minute = date.minute.toString().padLeft(2, '0');
  String second = date.second.toString().padLeft(2, '0');
  return '$dayName, $day $month $year $hour:$minute:$second GMT';
}

var REG = RegExp('^(${_WEEK_DAY.join('|')}), '
    r'(\d{2}) '
    '(${_MONTH.join('|')}) '
    r'(\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT$');

DateTime fromUTC(String input) {
  if (input == null || input.isEmpty) return null;
  var match = REG.firstMatch(input);
  if (match != null) {
    int day = int.parse(match[2]);
    int month = _MONTH.indexOf(match[3]) + 1;
    if (month == 0) {
      throw new Exception(
          '$input can not convert into date ${match[3]} is not current month');
    }
    int year = int.parse(match[4]);
    int hour = int.parse(match[5]);
    int minute = int.parse(match[6]);
    int second = int.parse(match[7]);
    return DateTime.utc(year, month, day, hour, minute, second, 0);
  } else {
    throw new FormatException('invalid utc date', input);
  }
}
