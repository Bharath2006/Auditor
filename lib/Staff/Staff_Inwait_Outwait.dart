import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:myapp/Firebasesetup.dart';
import '../models.dart';

class StaffWaitScreen extends StatefulWidget {
  const StaffWaitScreen({super.key});
  @override
  State<StaffWaitScreen> createState() => _StaffWaitScreenState();
}

class _StaffWaitScreenState extends State<StaffWaitScreen> {
  final String _uid = FirebaseService.auth.currentUser!.uid;
  String _userName = '';
  final _outFileCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();
  final _fileCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  String _statusFilter = 'InWait';
  final List<String> _statusOptions = ['All', 'InWait', 'OutWait'];

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final doc =
        await FirebaseService.firestore.collection('users').doc(_uid).get();
    if (doc.exists) {
      setState(() => _userName = doc['name'] ?? '');
    }
  }

  Future<void> _addInWait() async {
    if (_clientCtrl.text.isEmpty || _fileCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Client & File required'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    final docRef = FirebaseService.firestore.collection('wait_records').doc();
    final rec = WaitRecord(
      id: docRef.id,
      staffId: _uid,
      staffName: _userName,
      clientName: _clientCtrl.text.trim(),
      fileName: _fileCtrl.text.trim(),
      inWaitTime: DateTime.now(),
      outWaitTime: null,
      isCompleted: false,
      outFileName: null,
    );
    await docRef.set(rec.toMap());
    _clientCtrl.clear();
    _fileCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('In-Wait recorded'),
        backgroundColor: Colors.green,
      ),
    );
    setState(() => _isLoading = false);
  }

  Future<void> _addOutWaitDirect() async {
    if (_clientCtrl.text.isEmpty ||
        _fileCtrl.text.isEmpty ||
        _outFileCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Client, File & Output File required'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    final now = DateTime.now();
    final docRef = FirebaseService.firestore.collection('wait_records').doc();
    final rec = WaitRecord(
      id: docRef.id,
      staffId: _uid,
      staffName: _userName,
      clientName: _clientCtrl.text.trim(),
      fileName: _fileCtrl.text.trim(),
      inWaitTime: now,
      outWaitTime: now,
      isCompleted: true,
      outFileName: _outFileCtrl.text.trim(),
    );
    await docRef.set(rec.toMap());
    _clientCtrl.clear();
    _fileCtrl.clear();
    _outFileCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Out-Wait recorded directly'),
        backgroundColor: Colors.blue,
      ),
    );
    setState(() => _isLoading = false);
  }

  Future<void> _promptOutWait(WaitRecord rec) async {
    final outCtrl = TextEditingController(text: rec.outFileName ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Record Out-Wait'),
            content: TextField(
              controller: outCtrl,
              decoration: const InputDecoration(
                labelText: 'Output File Name',
                hintText: 'Type file name',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      await FirebaseService.firestore
          .collection('wait_records')
          .doc(rec.id)
          .update({
            'outWaitTime': DateTime.now(),
            'isCompleted': true,
            'outFileName': outCtrl.text.trim(),
          });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Out-Wait recorded'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String _fmt(DateTime dt) => DateFormat('dd/MM/yyyy HH:mm').format(dt);

  String _duration(DateTime inT, DateTime? outT) {
    if (outT == null) return '—';
    final d = outT.difference(inT);
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }

  bool _passesStatus(WaitRecord r) {
    if (_statusFilter == 'All') return true;
    return _statusFilter == 'InWait' ? !r.isCompleted : r.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Wait Records', style: GoogleFonts.openSans()),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDate,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // === Input Controls ===
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _clientCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Client',
                                  prefixIcon: const Icon(Icons.person),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _fileCtrl,
                                decoration: InputDecoration(
                                  labelText: 'File',
                                  prefixIcon: const Icon(
                                    Icons.insert_drive_file,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _outFileCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Output File',
                                  prefixIcon: const Icon(Icons.upload_file),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                              ),
                              onPressed: _addInWait,
                              child: const Text('In-Wait'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                backgroundColor: Colors.blueAccent,
                              ),
                              onPressed: _addOutWaitDirect,
                              child: const Text('Out-Wait Direct'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Search client or file',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            DropdownButton<String>(
                              value: _statusFilter,
                              items:
                                  _statusOptions
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) {
                                if (v != null)
                                  setState(() => _statusFilter = v);
                              },
                            ),
                          ],
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
                              .where('staffId', isEqualTo: _uid)
                              .orderBy('inWaitTime', descending: true)
                              .snapshots(),
                      builder: (ctx, snap) {
                        if (snap.hasError) {
                          return const Center(
                            child: Text('Error loading records'),
                          );
                        }
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final all =
                            snap.data!.docs
                                .map((d) {
                                  final m = d.data()! as Map<String, dynamic>;
                                  m['id'] = d.id;
                                  return WaitRecord.fromMap(m);
                                })
                                .where((r) {
                                  final dt = r.inWaitTime;
                                  final sameDay =
                                      dt.year == _selectedDate.year &&
                                      dt.month == _selectedDate.month &&
                                      dt.day == _selectedDate.day;
                                  final txt = _searchCtrl.text.toLowerCase();
                                  final matchesText =
                                      txt.isEmpty ||
                                      r.clientName.toLowerCase().contains(
                                        txt,
                                      ) ||
                                      r.fileName.toLowerCase().contains(txt);
                                  return sameDay &&
                                      matchesText &&
                                      _passesStatus(r);
                                })
                                .toList();

                        if (all.isEmpty) {
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
                                dataRowHeight: 56,
                                headingRowHeight: 56,
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'Client',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'File',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'In Time',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Out Time',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Out File',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Duration',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Status',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Action',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                rows: List.generate(all.length, (i) {
                                  final r = all[i];
                                  final isOut = r.isCompleted;
                                  return DataRow(
                                    color: MaterialStateProperty.resolveWith(
                                      (states) =>
                                          i.isOdd ? Colors.grey.shade50 : null,
                                    ),
                                    cells: [
                                      DataCell(Text(r.clientName)),
                                      DataCell(Text(r.fileName)),
                                      DataCell(Text(_fmt(r.inWaitTime))),
                                      DataCell(
                                        Text(
                                          r.outWaitTime != null
                                              ? _fmt(r.outWaitTime!)
                                              : '—',
                                        ),
                                      ),
                                      DataCell(Text(r.outFileName ?? '—')),
                                      DataCell(
                                        Text(
                                          _duration(
                                            r.inWaitTime,
                                            r.outWaitTime,
                                          ),
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
                                                    ? Colors.green.shade100
                                                    : Colors.red.shade100,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            isOut ? 'OutWait' : 'InWait',
                                            style: TextStyle(
                                              color:
                                                  isOut
                                                      ? Colors.green.shade900
                                                      : Colors.red.shade900,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        isOut
                                            ? const SizedBox.shrink()
                                            : ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.red.shade400,
                                              ),
                                              onPressed:
                                                  () => _promptOutWait(r),
                                              child: const Text('Out-Wait'),
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
