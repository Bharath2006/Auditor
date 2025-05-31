import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/Firebasesetup.dart';
import '../models.dart';

class StaffTaskScreen extends StatefulWidget {
  const StaffTaskScreen({super.key});

  @override
  State<StaffTaskScreen> createState() => _StaffTaskScreenState();
}

class _StaffTaskScreenState extends State<StaffTaskScreen> {
  final String _currentUserId = FirebaseService.auth.currentUser!.uid;
  String _searchText = '';
  String _selectedStatus = 'All';
  String _selectedEntity = 'All';
  String _selectedNatureOfWork = 'All';
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final List<String> _statuses = [
    'All',
    'Pending',
    'In Progress',
    'Complete',
    'Request_Pending',
  ];

  List<String> _entities = ['All', 'Individual', 'Company', 'LLP'];
  List<String> _natureOfWorks = ['All', 'IT', 'ROC', 'Profit & Loss', 'GST'];

  Future<void> _markTaskAsComplete(String taskId, String status) async {
    if (status == 'Request_Pending') return;
    try {
      final userTaskRef = FirebaseService.firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('assigned_tasks')
          .doc(taskId);
      final mainTaskRef = FirebaseService.firestore
          .collection('tasks')
          .doc(taskId);

      await userTaskRef.update({'status': 'Complete'});
      await mainTaskRef.update({'status': 'Complete'});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task marked as complete')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    IconData icon = Icons.filter_alt,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: DropdownButton<T>(
        value: value,
        icon: Icon(icon),
        underline: const SizedBox(),
        isExpanded: true,
        items:
            items
                .map(
                  (item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(item.toString()),
                  ),
                )
                .toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(12),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseService.firestore
                  .collection('users')
                  .doc(_currentUserId)
                  .collection('assigned_tasks')
                  .orderBy('deadline')
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No tasks assigned'));
            }

            List<Task> tasks =
                snapshot.data!.docs.map((doc) {
                  final taskData = doc.data() as Map<String, dynamic>;
                  return Task.fromMap({...taskData, 'id': doc.id});
                }).toList();

            final entitySet = <String>{};
            final workSet = <String>{};
            for (var t in tasks) {
              if (t.natureOfEntity.trim().isNotEmpty) {
                entitySet.add(t.natureOfEntity.trim());
              }
              if (t.natureOfWork.trim().isNotEmpty) {
                workSet.add(t.natureOfWork.trim());
              }
            }
            _entities =
                entitySet.isEmpty ? ['No Entity'] : ['All', ...entitySet];
            _natureOfWorks =
                workSet.isEmpty ? ['No Work'] : ['All', ...workSet];

            final searchLower = _searchText.toLowerCase();
            List<Task> filteredTasks =
                tasks.where((task) {
                  final matchesSearch =
                      _searchText.isEmpty ||
                      task.clientName.toLowerCase().contains(searchLower) ||
                      task.natureOfEntity.toLowerCase().contains(searchLower) ||
                      task.natureOfWork.toLowerCase().contains(searchLower);
                  final matchesStatus =
                      _selectedStatus == 'All' ||
                      task.status == _selectedStatus;
                  final matchesEntity =
                      _selectedEntity == 'All' ||
                      (_selectedEntity == 'No Entity' &&
                          task.natureOfEntity.trim().isEmpty) ||
                      task.natureOfEntity == _selectedEntity;
                  final matchesWork =
                      _selectedNatureOfWork == 'All' ||
                      (_selectedNatureOfWork == 'No Work' &&
                          task.natureOfWork.trim().isEmpty) ||
                      task.natureOfWork == _selectedNatureOfWork;
                  return matchesSearch &&
                      matchesStatus &&
                      matchesEntity &&
                      matchesWork;
                }).toList();

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Search and Filters
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              elevation: 2,
                              borderRadius: BorderRadius.circular(12),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText:
                                      'Search by client name, entity or work...',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon:
                                      _searchController.text.isNotEmpty
                                          ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() => _searchText = '');
                                            },
                                          )
                                          : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                onChanged:
                                    (val) => setState(() => _searchText = val),
                              ),
                            ),
                          ),
                          // Filters
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildDropdown<String>(
                                        label: 'Status',
                                        value: _selectedStatus,
                                        items: _statuses,
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(
                                              () => _selectedStatus = val,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildDropdown<String>(
                                        label: 'Entity',
                                        value: _selectedEntity,
                                        items: _entities,
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(
                                              () => _selectedEntity = val,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildDropdown<String>(
                                        label: 'Work',
                                        value: _selectedNatureOfWork,
                                        items: _natureOfWorks,
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(
                                              () => _selectedNatureOfWork = val,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // DataTable
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(
                              Colors.grey[200],
                            ),
                            columns: const [
                              DataColumn(label: Text('Client')),
                              DataColumn(label: Text('Entity')),
                              DataColumn(label: Text('Work')),
                              DataColumn(label: Text('Deadline')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Action')),
                            ],
                            rows:
                                filteredTasks.map((task) {
                                  final isOverdue =
                                      task.deadline.isBefore(DateTime.now()) &&
                                      task.status != 'Complete';
                                  return DataRow(
                                    color: MaterialStateProperty.resolveWith(
                                      (states) =>
                                          isOverdue ? Colors.red[50] : null,
                                    ),
                                    cells: [
                                      DataCell(Text(task.clientName)),
                                      DataCell(
                                        Text(
                                          task.natureOfEntity.trim().isEmpty
                                              ? 'No Entity'
                                              : task.natureOfEntity,
                                        ),
                                      ),
                                      DataCell(Text(task.natureOfWork)),
                                      DataCell(
                                        Text(
                                          DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(task.deadline),
                                          style: TextStyle(
                                            color:
                                                isOverdue
                                                    ? Colors.red[700]
                                                    : Colors.black,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Chip(
                                          label: Text(task.status),
                                          backgroundColor:
                                              task.status == 'Complete'
                                                  ? Colors.green[100]
                                                  : task.status ==
                                                      'Request_Pending'
                                                  ? Colors.grey[300]
                                                  : Colors.blue[100],
                                          labelStyle: TextStyle(
                                            color:
                                                task.status == 'Complete'
                                                    ? Colors.green[800]
                                                    : Colors.blue[800],
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        ElevatedButton(
                                          onPressed:
                                              (task.status == 'Complete' ||
                                                      task.status ==
                                                          'Request_Pending')
                                                  ? null
                                                  : () => _markTaskAsComplete(
                                                    task.id,
                                                    task.status,
                                                  ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                task.status == 'Complete'
                                                    ? Colors.grey
                                                    : Colors.green,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text('Complete'),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
