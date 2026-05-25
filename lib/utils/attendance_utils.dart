import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show Color, Colors;

/// Central attendance rules and ID formatting (single source of truth).
class AttendanceConfig {
  static const int defaultLateHour = 8;
  static const int defaultLateMinute = 0;
  static const int defaultWorkMinutes = 480;

  static Future<AttendanceConfig> loadFromFirestore() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('attendance')
          .get();
      if (!doc.exists || doc.data() == null) {
        return const AttendanceConfig();
      }
      final data = doc.data()!;
      return AttendanceConfig(
        lateHour: (data['late_hour'] as num?)?.toInt() ?? defaultLateHour,
        lateMinute: (data['late_minute'] as num?)?.toInt() ?? defaultLateMinute,
        standardWorkMinutes: (data['standard_work_minutes'] as num?)?.toInt() ??
            defaultWorkMinutes,
      );
    } catch (_) {
      return const AttendanceConfig();
    }
  }

  final int lateHour;
  final int lateMinute;
  final int standardWorkMinutes;

  const AttendanceConfig({
    this.lateHour = defaultLateHour,
    this.lateMinute = defaultLateMinute,
    this.standardWorkMinutes = defaultWorkMinutes,
  });

  DateTime cutoffForDay(DateTime day) => DateTime(
        day.year,
        day.month,
        day.day,
        lateHour,
        lateMinute,
      );

  bool isLate(DateTime timeIn) => timeIn.isAfter(cutoffForDay(timeIn));
}

/// `{employeeId}_{yyyy-MM-dd}` — always zero-padded month/day.
String attendanceDocId(String employeeId, [DateTime? date]) {
  final d = date ?? DateTime.now();
  final month = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${employeeId}_${d.year}-$month-$day';
}

String formatDateTime(DateTime date) {
  var hour = date.hour;
  final ampm = hour >= 12 ? 'PM' : 'AM';
  if (hour >= 12) hour = hour > 12 ? hour - 12 : hour;
  if (hour == 0) hour = 12;
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.month}/${date.day}/${date.year} - $hour:$minute $ampm';
}

String formatRecordDate(Timestamp? timestamp) {
  if (timestamp == null) return 'Unknown date';
  final date = timestamp.toDate();
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final weekday = weekdays[date.weekday - 1];
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$weekday, $month/$day/${date.year}';
}

String formatShortDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$month/$day/${date.year}';
}

String calculateHours(
  Timestamp? timeIn,
  Timestamp? timeOut, {
  int standardMinutes = AttendanceConfig.defaultWorkMinutes,
}) {
  if (timeIn == null) return '—';

  final start = timeIn.toDate();
  final end = timeOut?.toDate() ?? DateTime.now();
  final totalMinutes = end.difference(start).inMinutes;
  final regularMinutes =
      totalMinutes > standardMinutes ? standardMinutes : totalMinutes;
  final otMinutes =
      totalMinutes > standardMinutes ? totalMinutes - standardMinutes : 0;
  final regH = regularMinutes ~/ 60;
  final regM = regularMinutes % 60;
  final otH = otMinutes ~/ 60;
  final otM = otMinutes % 60;

  return otMinutes > 0
      ? '${regH}h ${regM}m + OT: ${otH}h ${otM}m'
      : '${regH}h ${regM}m';
}

String getDailyStatus(
  DateTime? timeIn, {
  AttendanceConfig config = const AttendanceConfig(),
}) {
  if (timeIn == null) return 'Absent';
  return config.isLate(timeIn) ? 'Late' : 'Present';
}

String getReportStatus(
  Map<String, dynamic> data, {
  AttendanceConfig config = const AttendanceConfig(),
}) {
  if (data['time_in'] == null) return 'ABSENT';

  final timeIn = (data['time_in'] as Timestamp).toDate();
  final timeOut = data['time_out'] != null
      ? (data['time_out'] as Timestamp).toDate()
      : null;
  final isLate = config.isLate(timeIn);
  final totalMinutes =
      timeOut != null ? timeOut.difference(timeIn).inMinutes : 0;
  final isUndertime =
      timeOut != null && totalMinutes < config.standardWorkMinutes;

  if (timeOut == null) {
    return isLate ? 'LATE (INCOMPLETE)' : 'PRESENT (INCOMPLETE)';
  }
  if (isUndertime) return 'UNDERTIME';
  if (isLate) return 'LATE';
  return 'PRESENT';
}

Color statusColor(String status) {
  final upper = status.toUpperCase();
  if (upper.contains('PRESENT')) return Colors.green;
  if (upper.contains('LATE')) return Colors.orange;
  if (upper.contains('UNDERTIME')) return Colors.amber;
  if (upper.contains('ABSENT')) return Colors.red;
  if (upper.contains('CANCELLED')) return Colors.grey;
  return Colors.grey;
}
