import 'package:flutter/material.dart';
import 'package:myapp/models.dart';
import '../Firebasesetup.dart';

class TaskAssignmentScreen extends StatefulWidget {
  const TaskAssignmentScreen({super.key});

  @override
  _TaskAssignmentScreenState createState() => _TaskAssignmentScreenState();
}

class _TaskAssignmentScreenState extends State<TaskAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  String _natureOfEntity = 'Individual';
  String _natureOfWork = 'IT';
  DateTime _assignDate = DateTime.now();
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  List<String> _selectedStaffIds = [];
  List<UserModel> _allStaff = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoading = true);
    final snapshot =
        await FirebaseService.firestore
            .collection('users')
            .where('role', isEqualTo: 'staff')
            .get();

    setState(() {
      _allStaff =
          snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
      _isLoading = false;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isAssignDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isAssignDate ? _assignDate : _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isAssignDate) {
          _assignDate = picked;
        } else {
          _deadline = picked;
        }
      });
    }
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate() || _selectedStaffIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one staff member'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final taskId = FirebaseService.firestore.collection('tasks').doc().id;
      final task = Task(
        id: taskId,
        clientName: _clientNameController.text.trim(),
        natureOfEntity: _natureOfEntity,
        natureOfWork: _natureOfWork,
        assignDate: _assignDate,
        deadline: _deadline,
        assignedStaffIds: _selectedStaffIds,
      );

      await FirebaseService.firestore
          .collection('tasks')
          .doc(taskId)
          .set(task.toMap());

      for (final staffId in _selectedStaffIds) {
        await FirebaseService.firestore
            .collection('users')
            .doc(staffId)
            .collection('assigned_tasks')
            .doc(taskId)
            .set(task.toMap());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task created and assigned successfully')),
      );

      _formKey.currentState!.reset();
      _clientNameController.clear();
      setState(() {
        _selectedStaffIds = [];
        _assignDate = DateTime.now();
        _deadline = DateTime.now().add(const Duration(days: 7));
      });
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Error creating task: ${e.toString()}')),
      // );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Client Name
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _clientNameController,
                    decoration: const InputDecoration(
                      labelText: 'Client Name',
                      contentPadding: EdgeInsets.all(16),
                      border: InputBorder.none,
                    ),
                    validator:
                        (value) =>
                            value!.isEmpty ? 'Please enter client name' : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Nature of Entity Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _natureOfEntity,
                    decoration: const InputDecoration(
                      labelText: 'Nature of Entity',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      border: InputBorder.none,
                    ),
                    items:
                        ['Individual', 'Company', 'LLP']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged:
                        (value) => setState(() => _natureOfEntity = value!),
                  ),
                ),
                const SizedBox(height: 16),

                // Nature of Work Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _natureOfWork,
                    decoration: const InputDecoration(
                      labelText: 'Nature of Work',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      border: InputBorder.none,
                    ),
                    items:
                        ['IT', 'ROC', 'Profit & Loss', 'GST']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged:
                        (value) => setState(() => _natureOfWork = value!),
                  ),
                ),
                const SizedBox(height: 16),

                // Date Pickers (Assign and Deadline)
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Assign Date',
                            contentPadding: EdgeInsets.all(16),
                          ),
                          child: Text(
                            '${_assignDate.day}/${_assignDate.month}/${_assignDate.year}',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Deadline',
                            contentPadding: EdgeInsets.all(16),
                          ),
                          child: Text(
                            '${_deadline.day}/${_deadline.month}/${_deadline.year}',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Assign to Staff
                const Text(
                  'Assign to Staff:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Column(
                  children:
                      _allStaff
                          .map(
                            (staff) => Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: CheckboxListTile(
                                title: Text(staff.name),
                                value: _selectedStaffIds.contains(staff.uid),
                                onChanged: (selected) {
                                  setState(() {
                                    if (selected!) {
                                      _selectedStaffIds.add(staff.uid);
                                    } else {
                                      _selectedStaffIds.remove(staff.uid);
                                    }
                                  });
                                },
                              ),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 24),

                // Create Task Button
                ElevatedButton(
                  onPressed: _createTask,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: const Text(
                    'Create Task',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
  }
}
