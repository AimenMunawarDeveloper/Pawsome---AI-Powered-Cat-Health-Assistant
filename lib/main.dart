import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text(
                "${TimeOfDay.now().hour}:${TimeOfDay.now().minute}",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Image.asset("assets/images/graph.png", height: 20, width: 20),
                  Image.asset("assets/images/wifi.png", height: 20, width: 20),
                  Image.asset(
                    "assets/images/battery.png",
                    height: 20,
                    width: 20,
                  ),
                ],
              ),
            ],
          ),
          backgroundColor: Color(0xFF929292),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB8B8E9), Color(0xFFFFFFFF)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Image.asset("assets/images/logo.png")],
            ),
          ),
        ),
        backgroundColor: Color.fromRGBO(183, 33, 33, 1),
      ),
    );
  }
}
