import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:myapp/Firebasesetup.dart';
import '../models.dart';

class AdminWaitRecordsScreen extends StatefulWidget {
  const AdminWaitRecordsScreen({super.key});

  @override
  State<AdminWaitRecordsScreen> createState() => _AdminWaitRecordsScreenState();
}

class _AdminWaitRecordsScreenState extends State<AdminWaitRecordsScreen> {
  // Top‐level search & filter
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  final List<String> _statuses = ['All', 'InWait', 'OutWait'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) => DateFormat('dd/MM/yyyy HH:mm').format(dt);

  String _calcDuration(DateTime inTime, DateTime? outTime) {
    if (outTime == null) return '—';
    final dur = outTime.difference(inTime);
    return '${dur.inHours}h ${dur.inMinutes.remainder(60)}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wait Records Overview')),
      body: Column(
        children: [
          // === Search + Status Filter ===
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Search box
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                              : null,
                      hintText: 'Search Staff, Client or File...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),

                const SizedBox(width: 16),

                // Status dropdown (InWait / OutWait)
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                    ),
                    items:
                        _statuses
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedStatus = v);
                    },
                  ),
                ),
              ],
            ),
          ),

          // === Data Table ===
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseService.firestore
                      .collection('wait_records')
                      .orderBy('inWaitTime', descending: true)
                      .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('Error loading records'));
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final all =
                    snap.data!.docs.map((doc) {
                      final data = doc.data()! as Map<String, dynamic>;
                      data['id'] = doc.id;
                      return WaitRecord.fromMap(data);
                    }).toList();

                // Apply search + native‐status filter
                final filtered =
                    all.where((r) {
                      final txt = _searchController.text.toLowerCase();
                      final matchesSearch =
                          txt.isEmpty ||
                          r.staffName.toLowerCase().contains(txt) ||
                          r.clientName.toLowerCase().contains(txt) ||
                          r.fileName.toLowerCase().contains(txt);
                      final matchesStatus =
                          _selectedStatus == 'All' ||
                          (_selectedStatus == 'OutWait' && r.isCompleted) ||
                          (_selectedStatus == 'InWait' && !r.isCompleted);
                      return matchesSearch && matchesStatus;
                    }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No records found.'));
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                          Colors.grey.shade200,
                        ),
                        dataRowHeight: 60,
                        headingRowHeight: 56,
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Staff',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Client',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'File',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'In Time',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Out Time',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Duration',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Status',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        rows: List.generate(filtered.length, (i) {
                          final r = filtered[i];
                          final nativeStatus =
                              r.isCompleted ? 'OutWait' : 'InWait';
                          final isOut = r.isCompleted;

                          return DataRow(
                            color: MaterialStateProperty.resolveWith<Color?>((
                              states,
                            ) {
                              return i.isOdd
                                  ? Colors.grey.shade50
                                  : Colors.white;
                            }),
                            cells: [
                              DataCell(Text(r.staffName)),
                              DataCell(Text(r.clientName)),
                              DataCell(Text(r.fileName)),
                              DataCell(Text(_formatDate(r.inWaitTime))),
                              DataCell(
                                Text(
                                  r.outWaitTime != null
                                      ? _formatDate(r.outWaitTime!)
                                      : '—',
                                ),
                              ),
                              DataCell(
                                Text(
                                  _calcDuration(r.inWaitTime, r.outWaitTime),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isOut
                                            ? Colors.lightBlue.shade100
                                            : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isOut
                                            ? Icons
                                                .login // “in” icon for OutWait
                                            : Icons.hourglass_bottom_outlined,
                                        size: 18,
                                        color:
                                            isOut
                                                ? Colors.lightBlue.shade700
                                                : Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        nativeStatus,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isOut
                                                  ? Colors.lightBlue.shade700
                                                  : Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
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
            ),
          ),
        ],
      ),
    );
  }
}
