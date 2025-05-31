import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'Firebasesetup.dart';
import 'Admin/admin_dashboard.dart';
import 'auth.dart';
import 'models.dart';
import 'Staff/staffdashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Management System',
            debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseService.auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasData) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseService.firestore
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final user = UserModel.fromMap(
                      userSnapshot.data!.data() as Map<String, dynamic>);
                  return user.role == 'admin' 
                      ? AdminDashboard() 
                      : StaffDashboard();
                }
                
                return const AuthScreen();
              },
            );
          }
          return const AuthScreen();
        },
      ),
    );
  }
}