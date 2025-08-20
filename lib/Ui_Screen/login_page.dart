import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackingapp/Ui_Screen/tracking_page.dart' show TrackingPage;
import '../utilities/MyString.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool("isLoggedIn") ?? false;

    if (isLoggedIn) {
      // Auto-login if already stored
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TrackingPage()),
      );
    } else {
      // Pre-fill with default values
      _nameController.text = "karthick";
      _emailController.text = "karthickboy859@gmail.com";
    }
  }

  Future<void> _login() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter all details")));
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isLoggedIn", true);
    await prefs.setString("userName", _nameController.text);
    await prefs.setString("userEmail", _emailController.text);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TrackingPage()),
    );
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
              TextField(
                controller: _nameController,
                style: TextStyle(fontFamily: MyString.poppins),

                decoration: const InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                style: TextStyle(fontFamily: MyString.poppins),
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: ElevatedButton(
                  onPressed: _login,
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: MyString.poppins,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
