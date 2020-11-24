// @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Last-Modified
const WEEK_DAY = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
const MONTH = [
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
  String dayName = WEEK_DAY[date.weekday - 1];
  String day = date.day.toString().padLeft(2, '0');
  String month = MONTH[date.month - 1];
  String year = date.year.toString().padLeft(4, '0');
  String hour = date.hour.toString().padLeft(2, '0');
  String minute = date.minute.toString().padLeft(2, '0');
  String second = date.second.toString().padLeft(2, '0');
  return '$dayName, $day $month $year $hour:$minute:$second GMT';
}

DateTime fromUTC(String input) {
  if (input == null) return null;
  var list = input.split(RegExp(r'[ :]'));
  if (list.length != 8) {
    throw new Exception('$input is not utc format');
  }
  int day = int.parse(list[1]);
  int month = MONTH.indexOf(list[2]) + 1;
  if (month == 0)
    throw new Exception(
        '$input can not convert into date ${list[2]} is not current month');
  int year = int.parse(list[3]);
  int hour = int.parse(list[4]);
  int minute = int.parse(list[5]);
  int second = int.parse(list[6]);
  if (list[7] != 'GMT') {
    throw new Exception(
        '$input can not convert into date, GTM should always be GMT but got ${list[7]}');
  }
  return DateTime.utc(year, month, day, hour, minute, second, 0);
}
