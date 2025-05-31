import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../Firebasesetup.dart';
import '../models.dart';
import 'Admin_Attendence_Approval.dart';
import 'Admin_Attendence_Details.dart';

class StaffAttendanceScreen extends StatefulWidget {
  const StaffAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<StaffAttendanceScreen> createState() => _StaffAttendanceScreenState();
}

class _StaffAttendanceScreenState extends State<StaffAttendanceScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Attendance'),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF3F4F6),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseService.firestore
                .collection('users')
                .where('role', isEqualTo: 'staff')
                .snapshots(),
        builder: (context, snapshot) {
          // Display loading indicator while waiting
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Check for Firebase errors
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading staff: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          // Catch null data or empty documents
          if (!snapshot.hasData || snapshot.data?.docs.isEmpty == true) {
            return const Center(child: Text('No staff members found'));
          }

          List<UserModel> staffList = [];

          try {
            staffList =
                snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>?;

                  if (data == null) {
                    throw Exception('Staff data is null');
                  }

                  return UserModel.fromMap(data);
                }).toList();
          } catch (e) {
            return Center(
              child: Text(
                'Error parsing staff data: $e',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: staffList.length,
            itemBuilder: (context, index) {
              final staff = staffList[index];

              // Safety check
              if (staff.name.isEmpty || staff.email.isEmpty) {
                return const SizedBox.shrink(); // skip rendering incomplete entry
              }

              final colorVariants = [
                Colors.purple,
                Colors.teal,
                Colors.orange,
                Colors.blue,
              ];
              final patternColor = colorVariants[index % colorVariants.length];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      patternColor.withOpacity(0.9),
                      patternColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: patternColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: Text(
                      staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 20,
                        color: patternColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    staff.name,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    staff.email,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                  ),
                  onTap: () {
                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  StaffAttendanceDetailScreen(staff: staff),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Navigation failed: $e')),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminAttendanceApprovalScreen()),
      );
    },
    backgroundColor: Colors.deepPurpleAccent,
    tooltip: 'Add Attendance',
    child: const Icon(Icons.add),
  ),
    );
  }
}
