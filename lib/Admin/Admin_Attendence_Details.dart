import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models.dart';
import 'package:table_calendar/table_calendar.dart';

import 'Admin_Request_Approval.dart';

class StaffAttendanceDetailScreen extends StatefulWidget {
  final UserModel staff;

  const StaffAttendanceDetailScreen({super.key, required this.staff});

  @override
  _StaffAttendanceDetailScreenState createState() =>
      _StaffAttendanceDetailScreenState();
}

class _StaffAttendanceDetailScreenState
    extends State<StaffAttendanceDetailScreen>
    with TickerProviderStateMixin {
  final Map<DateTime, AttendanceStatus> _attendanceMap = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = false;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<List<WorkDetail>> _getWorkDetailsForDay(DateTime date) async {
    try {
      final dateKey = DateTime(date.year, date.month, date.day);
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.staff.uid)
              .collection('workDetails')
              .where(
                'date',
                isGreaterThanOrEqualTo: dateKey.millisecondsSinceEpoch,
              )
              .where(
                'date',
                isLessThan:
                    dateKey.add(const Duration(days: 1)).millisecondsSinceEpoch,
              )
              .orderBy('date')
              .get();

      return snapshot.docs
          .map((doc) => WorkDetail.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching work details: $e');
      return [];
    }
  }

  Duration _calculateTotalWorkDuration(List<WorkDetail> workDetails) {
    Duration total = Duration.zero;
    for (final detail in workDetails) {
      final start = DateTime(
        2023,
        1,
        1,
        detail.startTime.hour,
        detail.startTime.minute,
      );
      final end = DateTime(
        2023,
        1,
        1,
        detail.endTime.hour,
        detail.endTime.minute,
      );
      total += end.difference(start);
    }
    return total;
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.staff.uid)
              .collection('attendance')
              .get();

      _attendanceMap.clear();

      for (var doc in snapshot.docs) {
        final record = AttendanceRecord.tryFromMap(doc.data());
        if (record == null) continue; // Skip invalid records

        final date = DateTime(
          record.date.year,
          record.date.month,
          record.date.day,
        );

        if (record.type != null && record.type == 'Leave') {
          _attendanceMap[date] = AttendanceStatus.onLeave;
        } else if (record.clockIn != null && record.clockOut != null) {
          _attendanceMap[date] = AttendanceStatus.present;
        } else if (record.clockIn == null && record.clockOut == null) {
          _attendanceMap[date] = AttendanceStatus.absent;
        } else {
          _attendanceMap[date] = AttendanceStatus.partial;
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading attendance: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  final Color _gradientStart = const Color(0xFF6A11CB);
  final Color _gradientEnd = const Color(0xFF2575FC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildGradientAppBar(),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _buildLegend(),
                  _buildCalendar(),
                  const Divider(height: 1),
                  Expanded(child: _buildAttendanceList()),
                ],
              ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.beach_access),
        label: const Text('Leave Requests'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LeaveApprovalPage()),
          );
        },
        backgroundColor: _gradientEnd,
        elevation: 8,
      ),
      
      backgroundColor: Colors.grey[50],
    );
  }

  PreferredSizeWidget _buildGradientAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradientStart, _gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: AppBar(
          title: Text(
            "${widget.staff.name}'s Attendance",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, size: 26),
              onPressed: _loadAttendance,
              tooltip: 'Refresh',
            ),
          ],
          centerTitle: true,
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _legendItem('Present', Colors.green.shade400),
          _legendItem('Absent', Colors.red.shade400),
          _legendItem('Partial', Colors.orange.shade400),
          _legendItem('Leave', Colors.blue.shade400),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.7),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TableCalendar(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
            _animationController.forward(from: 0);
          });
        },
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF444444),
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: _gradientEnd),
          rightChevronIcon: Icon(Icons.chevron_right, color: _gradientEnd),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: const TextStyle(fontWeight: FontWeight.w600),
          weekendTextStyle: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
          todayDecoration: BoxDecoration(
            color: _gradientStart,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _gradientStart.withOpacity(0.6),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          selectedDecoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_gradientStart, _gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _gradientEnd.withOpacity(0.7),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          markerDecoration: const BoxDecoration(),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            final date = DateTime(day.year, day.month, day.day);
            final status = _attendanceMap[date];

            if (status == null) {
              return Center(child: Text('${day.day}'));
            }

            Color bgColor;
            Color textColor = Colors.white;

            switch (status) {
              case AttendanceStatus.present:
                bgColor = Colors.green.shade400;
                break;
              case AttendanceStatus.absent:
                bgColor = Colors.red.shade400;
                break;
              case AttendanceStatus.partial:
                bgColor = Colors.orange.shade400;
                break;
              case AttendanceStatus.onLeave:
                bgColor = Colors.blue.shade400;
                break;
            }

            return Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: bgColor.withOpacity(0.6),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text('${day.day}', style: TextStyle(color: textColor)),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    final dates = _attendanceMap.keys.toList()..sort((a, b) => b.compareTo(a));
    return ListView.builder(
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final status = _attendanceMap[date];
        final formatted = DateFormat('EEE, MMM d, yyyy').format(date);

        return FutureBuilder<List<WorkDetail>>(
          future: _getWorkDetailsForDay(date),
          builder: (context, snapshot) {
            final workDetails = snapshot.data ?? [];
            final totalDuration = _calculateTotalWorkDuration(workDetails);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: _statusToColor(status),
                  child: Icon(_statusToIcon(status), color: Colors.white),
                ),
                title: Text(
                  formatted,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  '${_statusToText(status)}${totalDuration.inMinutes > 0 ? ' • ${totalDuration.inHours}h ${totalDuration.inMinutes.remainder(60)}m' : ''}',
                  style: const TextStyle(color: Colors.black54),
                ),
                children: [
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (workDetails.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('No work details for this day'),
                    )
                  else
                    ...workDetails
                        .map(
                          (detail) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${detail.startTime.format(context)} - ${detail.endTime.format(context)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (detail.description.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 24.0,
                                      top: 4,
                                    ),
                                    child: Text(detail.description),
                                  ),
                                const Divider(),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _statusToText(AttendanceStatus? status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.partial:
        return 'Partial';
      case AttendanceStatus.onLeave:
        return 'On Leave';
      default:
        return 'No Record';
    }
  }

  IconData _statusToIcon(AttendanceStatus? status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.partial:
        return Icons.timelapse;
      case AttendanceStatus.onLeave:
        return Icons.beach_access;
      default:
        return Icons.help_outline;
    }
  }

  Color _statusToColor(AttendanceStatus? status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.partial:
        return Colors.orange;
      case AttendanceStatus.onLeave:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

enum AttendanceStatus { present, absent, partial, onLeave }

class WorkDetail {
  final String id;
  final String userId;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String description;

  WorkDetail({
    required this.id,
    required this.userId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.description,
  });

  factory WorkDetail.fromMap(Map<String, dynamic> data) {
    return WorkDetail(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(data['date']),
      startTime: TimeOfDay(
        hour: data['startHour'] ?? 0,
        minute: data['startMinute'] ?? 0,
      ),
      endTime: TimeOfDay(
        hour: data['endHour'] ?? 0,
        minute: data['endMinute'] ?? 0,
      ),
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.millisecondsSinceEpoch,
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
      'description': description,
    };
  }
}
