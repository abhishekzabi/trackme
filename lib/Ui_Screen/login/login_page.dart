import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackingapp/Ui_Screen/homepage/home_page.dart';

import '../../utilities/MyString.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formkey = GlobalKey<FormState>();
  final _emailfirebaseController = TextEditingController();
  final _passwordcontroller = TextEditingController();

  bool _isLoading = false;
Future<void> loginUser(String email, String password) async {
  setState(() {
    _isLoading = true;
  });

  try {
    // Step 1: Firebase Authentication
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    User? user = userCredential.user;

    if (user != null) {
      // Step 2: Save details in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('uid', user.uid);
      await prefs.setString('email', user.email ?? "");
      await prefs.setBool('isLoggedIn', true);

      // Step 3: Save/Update details in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge:true = won’t overwrite old data

      // Step 4: Success message & navigation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login successful!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TrackingPage()),
      );
    }
  } on FirebaseAuthException catch (e) {
    String errorMessage;

    if (e.code == 'user-not-found') {
      errorMessage = "No user found for that email.";
    } else if (e.code == 'wrong-password') {
      errorMessage = "Wrong password.";
    } else {
      errorMessage = "Something went wrong. Please try again.";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF9FAFC),
      appBar: AppBar(
        backgroundColor: Color(0xff0D0D3C),
        centerTitle: true,
        title: Text(
          "Tracking App",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontFamily: MyString.poppins,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    "Hello,Friend!",
                    style: TextStyle(
                      fontFamily: MyString.poppins,
                      fontSize: 30,
                    ),
                  ),
                  SizedBox(height: 20),

                  Text(
                    "Enter your Personal Details",
                    style: TextStyle(
                      fontFamily: MyString.poppins,
                      fontSize: 16,
                      fontWeight: FontWeight.w200,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 5),

                  Text(
                    "and start journey with us",
                    style: TextStyle(
                      fontFamily: MyString.poppins,
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              Image.asset("assets/login image.png", height: 200),
              SizedBox(height: 50),
              Form(
                key: _formkey,
                child: Column(
                  children: [
                    TextField(
                      controller: _emailfirebaseController,
                      style: TextStyle(fontFamily: MyString.poppins),

                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextField(
                      controller: _passwordcontroller,
                      style: TextStyle(fontFamily: MyString.poppins),
                      decoration: const InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formkey.currentState!.validate()) {
                            loginUser(
                              _emailfirebaseController.text.trim(),
                              _passwordcontroller.text.trim(),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xffA2D65F),
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ), // button height
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              10,
                            ), // rounded corners
                          ),
                        ),
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: MyString.poppins,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
