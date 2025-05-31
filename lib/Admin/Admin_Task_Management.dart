import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/Firebasesetup.dart';
import '../models.dart';
import 'Admin_Task_Assigned.dart';
import 'Task_Editing.dart';

class TaskListTab extends StatefulWidget {
  const TaskListTab({super.key});
  @override
  State<TaskListTab> createState() => _TaskListTabState();
}

class _TaskListTabState extends State<TaskListTab> {
  String _clientFilter = '';
  String _assignedToFilter = '';
  String _workFilter = 'All';
  String _entityFilter = 'All';
  String _statusFilter = 'All';

  final List<String> _statuses = [
    'All',
    'Pending',
    'In Progress',
    'Complete',
    'Request_Pending',
    'Approved',
  ];
  List<String> _entities = ['All'];
  List<String> _natureOfWorks = ['All'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Task List',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _clientFilter = '';
                      _assignedToFilter = '';
                      _workFilter = 'All';
                      _entityFilter = 'All';
                      _statusFilter = 'All';
                    });
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Filters'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseService.firestore
                      .collection('tasks')
                      .orderBy('deadline')
                      .snapshots(),
              builder: (context, taskSnap) {
                if (taskSnap.hasError) {
                  return const Center(child: Text('Error loading tasks'));
                }
                if (taskSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rawTasks =
                    taskSnap.data!.docs
                        .map((d) {
                          try {
                            return Task.fromMap(
                              d.data()! as Map<String, dynamic>,
                            );
                          } catch (_) {
                            return null;
                          }
                        })
                        .whereType<Task>()
                        .toList();

                final entSet = <String>{};
                final workSet = <String>{};
                for (var t in rawTasks) {
                  if (t.natureOfEntity.trim().isNotEmpty) {
                    entSet.add(t.natureOfEntity.trim());
                  }
                  if (t.natureOfWork.trim().isNotEmpty) {
                    workSet.add(t.natureOfWork.trim());
                  }
                }
                _entities = ['All', ...entSet];
                _natureOfWorks = ['All', ...workSet];

                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchTasksWithStaff(rawTasks),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final list =
                        (snap.data ?? []).where((m) {
                          final t = m['task'] as Task;
                          final names = List<String>.from(
                            m['staffNames'] ?? [],
                          );
                          if (_clientFilter.isNotEmpty &&
                              !t.clientName.toLowerCase().contains(
                                _clientFilter.toLowerCase(),
                              )) {
                            return false;
                          }
                          if (_assignedToFilter.isNotEmpty &&
                              !names.any(
                                (n) => n.toLowerCase().contains(
                                  _assignedToFilter.toLowerCase(),
                                ),
                              )) {
                            return false;
                          }
                          if (_workFilter != 'All' &&
                              t.natureOfWork != _workFilter) {
                            return false;
                          }
                          if (_entityFilter != 'All' &&
                              t.natureOfEntity != _entityFilter) {
                            return false;
                          }
                          if (_statusFilter != 'All' &&
                              t.status != _statusFilter) {
                            return false;
                          }
                          return true;
                        }).toList();

                    if (list.isEmpty) {
                      return const Center(child: Text('No tasks found.'));
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowHeight: 80,
                            dataRowHeight: 60,
                            headingRowColor: MaterialStateProperty.all(
                              Colors.grey[100],
                            ),
                            columns: _buildColumns(),
                            rows: List.generate(list.length, (i) {
                              final map = list[i];
                              final t = map['task'] as Task;
                              final names = List<String>.from(
                                map['staffNames'] ?? [],
                              );
                              final overdue =
                                  t.deadline.isBefore(DateTime.now()) &&
                                  t.status.toLowerCase() != 'complete';
                              return DataRow(
                                color: MaterialStateProperty.resolveWith((s) {
                                  if (overdue) return Colors.red[50];
                                  return (i % 2 == 1)
                                      ? Colors.grey[50]
                                      : Colors.white;
                                }),
                                cells: [
                                  DataCell(
                                    Text(
                                      t.clientName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(t.natureOfWork)),
                                  DataCell(
                                    Text(
                                      t.natureOfEntity.isEmpty
                                          ? 'No Entity'
                                          : t.natureOfEntity,
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(t.deadline),
                                      style: TextStyle(
                                        color: overdue ? Colors.red : null,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(names.join(', '))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _statusColor(t.status),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        t.status,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _editTask(t),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        tooltip: 'Create New Task',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TaskAssignmentScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<DataColumn> _buildColumns() => [
    DataColumn(
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Client', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          SizedBox(
            width: 120,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Filter',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              onChanged: (v) => setState(() => _clientFilter = v),
            ),
          ),
        ],
      ),
    ),
    DataColumn(
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Work', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          DropdownButton<String>(
            isDense: true,
            value: _workFilter,
            onChanged:
                (v) => v != null ? setState(() => _workFilter = v) : null,
            items:
                _natureOfWorks
                    .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                    .toList(),
          ),
        ],
      ),
    ),
    DataColumn(
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Entity', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          DropdownButton<String>(
            isDense: true,
            value: _entityFilter,
            onChanged:
                (v) => v != null ? setState(() => _entityFilter = v) : null,
            items:
                _entities
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
          ),
        ],
      ),
    ),
    const DataColumn(
      label: Text('Deadline', style: TextStyle(fontWeight: FontWeight.bold)),
    ),
    DataColumn(
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assigned To',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 120,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Filter',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              onChanged: (v) => setState(() => _assignedToFilter = v),
            ),
          ),
        ],
      ),
    ),
    DataColumn(
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          DropdownButton<String>(
            isDense: true,
            value: _statusFilter,
            onChanged:
                (v) => v != null ? setState(() => _statusFilter = v) : null,
            items:
                _statuses
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
          ),
        ],
      ),
    ),
    const DataColumn(
      label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
    ),
  ];

  Future<List<Map<String, dynamic>>> _fetchTasksWithStaff(
    List<Task> tasks,
  ) async {
    final out = <Map<String, dynamic>>[];
    for (var t in tasks) {
      final names = <String>[];
      for (var id in t.assignedStaffIds) {
        try {
          final doc =
              await FirebaseService.firestore.collection('users').doc(id).get();
          if (doc.exists) names.add(doc.data()?['name'] ?? '—');
        } catch (_) {}
      }
      out.add({'task': t, 'staffNames': names});
    }
    return out;
  }

  Future<void> _editTask(Task t) async {
    final res = await showDialog(
      context: context,
      builder: (_) => TaskEditDialog(task: t),
    );
    if (res == true) setState(() {});
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'complete':
        return Colors.green[100]!;
      case 'in progress':
        return Colors.blue[100]!;
      case 'approved':
        return Colors.lightBlue[100]!;
      case 'request_pending':
        return Colors.grey[300]!;
      default:
        return Colors.orange[100]!;
    }
  }
}
