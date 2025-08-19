import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:trackingapp/auth_gate/auth_gate.dart';
import 'package:trackingapp/firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );


  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home:  AuthGate(),
  ));
}



