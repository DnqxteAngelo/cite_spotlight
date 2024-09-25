// ignore_for_file: use_super_parameters, prefer_const_constructors, library_private_types_in_public_api, use_build_context_synchronously

import 'package:animate_do/animate_do.dart';
import 'package:cite_spotlight/admin_pages/admin_page.dart';
import 'package:cite_spotlight/user_pages/landing_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://atsgdlgyikeqipysmvzf.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF0c2dkbGd5aWtlcWlweXNtdnpmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjY5MzIxMTgsImV4cCI6MjA0MjUwODExOH0.wtQc2ZdSk5P7J91WsR73Hv2waAEDIVV2xubKG2NOpJs',
  );
  runApp(Main());
}

class Main extends StatelessWidget {
  const Main({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.green.shade900,
          contentTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          actionTextColor: Colors.yellow,
          behavior: SnackBarBehavior.floating,
          elevation: 6.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController studentIdController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> login() async {
    final studentId = studentIdController.text.trim();
    final password = passwordController.text.trim();

    try {
      // Query the database to check credentials
      final response = await Supabase.instance.client
          .from('tbl_users')
          .select()
          .eq('user_studentId', studentId)
          .eq('user_password', password)
          .single();

      // Check if a user was found
      if (response.isNotEmpty) {
        // Login successful
        final userName = response['user_name'];
        final userId = response['user_id'];

        studentIdController.clear();
        passwordController.clear();

        setState(() {
          _obscurePassword = true;
        });

        // Check if the user is admin
        if (studentId == "admin") {
          // Navigate to AdminPage
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AdminPage()), // Add AdminPage
          );
        } else {
          // Navigate to LandingPage for regular users
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Login successful!\nWelcome, $userName')), // Display user_name
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LandingPage(
                userId: userId,
              ),
            ), // Add LandingPage
          );
        }
      } else {
        // Invalid credentials
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid Student ID or Password')),
        );
      }
    } catch (e) {
      // Handle any exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incorrect Student ID or Password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final buttonPadding = screenSize.width * 0.03;
    final isLargeScreen = screenSize.width > 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [
              Colors.green.shade800,
              Colors.green.shade600,
              Colors.green.shade400,
            ],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: screenSize.height * 0.1),
            Padding(
              padding: EdgeInsets.all(buttonPadding),
              child: Column(
                children: [
                  FadeInLeft(
                    duration: Duration(milliseconds: 300),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: buttonPadding),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        "C I T E",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize:
                              isLargeScreen ? 60 : screenSize.width * 0.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  FadeInLeft(
                    duration: Duration(milliseconds: 400),
                    child: Text(
                      "Spotlight",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isLargeScreen ? 40 : screenSize.width * 0.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  FadeInLeft(
                    duration: Duration(milliseconds: 500),
                    child: Text(
                      "Who got the best face?",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isLargeScreen ? 20 : screenSize.width * 0.05,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenSize.height * 0.03),
            Expanded(
              child: FadeInUp(
                duration: Duration(milliseconds: 600),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(60),
                      topRight: Radius.circular(60),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(isLargeScreen ? 60.0 : 30.0),
                      child: Column(
                        children: [
                          SizedBox(height: 10),
                          FadeInLeft(
                            duration: Duration(milliseconds: 700),
                            child: Text(
                              "Login to your account",
                              style: TextStyle(
                                color: Colors.green.shade600,
                                fontSize: isLargeScreen
                                    ? 32
                                    : screenSize.width * 0.08,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(height: screenSize.height * 0.03),
                          FadeInUp(
                            duration: Duration(milliseconds: 800),
                            child: Container(
                              width: isLargeScreen
                                  ? screenSize.width * 0.5
                                  : double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.shade200,
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                            color: Colors.grey.shade200),
                                      ),
                                    ),
                                    child: TextField(
                                      controller: studentIdController,
                                      decoration: InputDecoration(
                                        labelText: "Student ID #",
                                        labelStyle: TextStyle(
                                            color: Colors.green.shade600),
                                        hintText: "e.g. 00-0000-000000",
                                        hintStyle:
                                            TextStyle(color: Colors.grey),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    child: TextField(
                                      controller: passwordController,
                                      obscureText:
                                          _obscurePassword, // Use the _obscurePassword variable
                                      decoration: InputDecoration(
                                        labelText: "Password",
                                        labelStyle: TextStyle(
                                            color: Colors.green.shade600),
                                        hintText: "Enter your password",
                                        hintStyle:
                                            TextStyle(color: Colors.grey),
                                        border: InputBorder.none,
                                        suffixIcon: IconButton(
                                          // Add this IconButton
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: Colors.green.shade600,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: screenSize.height * 0.08),
                          FadeInUp(
                            duration: Duration(milliseconds: 800),
                            child: SizedBox(
                              width: isLargeScreen
                                  ? screenSize.width * 0.3
                                  : double.infinity,
                              child: MaterialButton(
                                onPressed: login, // Call the login function
                                height: 50,
                                color: Colors.green.shade800,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Center(
                                  child: Text(
                                    "Login",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
