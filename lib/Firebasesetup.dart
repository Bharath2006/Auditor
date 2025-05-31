import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: 'AIzaSyAtNu4FhDfVgtuBVCX_9l8IIdYmhGNhXeg',
        appId: '1:906357188964:web:56f72367613ce3063af271',
        messagingSenderId: '906357188964',
        projectId: 'voyage-4fb27',
        authDomain: 'voyage-4fb27.firebaseapp.com',
        storageBucket: 'voyage-4fb27.firebasestorage.app',
        measurementId: 'G-41L1KY95BC',
      ),
    );
  }

  static FirebaseAuth get auth => _auth;
  static FirebaseFirestore get firestore => _firestore;
}
