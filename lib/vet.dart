import 'package:flutter/material.dart';
import "chat.dart";
import "profile.dart";
import "logs.dart";
import "health.dart";
import "home.dart";
import 'package:google_fonts/google_fonts.dart';

class Vet extends StatefulWidget {
  const Vet({super.key});

  @override
  State<Vet> createState() => _VetState();
}

class _VetState extends State<Vet> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFD0DB),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Stack(
                children: [
                  // Map Image
                  Positioned.fill(
                    child: Image.asset(
                      "assets/images/map.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 120,
                    left: 40,
                    child: _buildDoctorCard(
                      name: "Dr.Hafsa",
                      specialty: "Internal Medicine",
                      phone: "+92 3637936633",
                      color: const Color(0xFFB8B8E9),
                    ),
                  ),
                  Positioned(
                    bottom: 120,
                    left: 20,
                    child: _buildDoctorCard(
                      name: "Dr.Ahmed Ali",
                      specialty: "Internal Medicine",
                      phone: "+92 9232936633",
                      color: const Color(0xFFE7B2BD),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildClinicList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      color: const Color(0xFFB8B8E9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
          Row(
            children: [
              Image.asset("assets/images/logo.png", height: 28, width: 28),
              const SizedBox(width: 8),
              Text(
                "Pawsome",
                style: GoogleFonts.leckerliOne(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Icon(Icons.notifications_none, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.grey[200],
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              _drawerItem(Icons.home, "Home", () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Home()),
                );
              }),

              _drawerItem(Icons.list_alt, "Logs", () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Logs()),
                );
              }),

              _drawerItem(Icons.favorite, "Health", () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Health()),
                );
              }),

              _drawerItem(Icons.auto_awesome, "AI Chat", () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Chat()),
                );
              }),

              _drawerItem(Icons.location_on, "Vet Locator", () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Vet()),
                );
              }),

              _drawerItem(Icons.person, "Profile", () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Profile()),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.black87),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDoctorCard({
    required String name,
    required String specialty,
    required String phone,
    required Color color,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(specialty, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.phone, size: 14),
              const SizedBox(width: 5),
              Expanded(
                child: Text(phone, style: const TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClinicList() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildClinicTile(
            "Care for My Pet",
            "Family Clinic • Sector G-13",
            "Closes at 5PM",
            3.9,
          ),
          const Divider(),
          _buildClinicTile(
            "Abdul Aziz",
            "Dentistry • Sector H-12",
            "Closes at 5PM",
            4.0,
          ),
        ],
      ),
    );
  }

  Widget _buildClinicTile(
    String name,
    String subtitle,
    String time,
    double rating,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Text(rating.toString()),
                  const Icon(Icons.star, size: 14, color: Colors.orange),
                ],
              ),
              Text(subtitle),
              Text(time, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        Column(
          children: const [
            Icon(Icons.phone, color: Colors.blue),
            Text("Call", style: TextStyle(color: Colors.blue)),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFFB8B8E9),
      selectedItemColor: Colors.purple,
      unselectedItemColor: Colors.white,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
          );
        }
        if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Logs()),
          );
        }
        if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Health()),
          );
        }
        if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Chat()),
          );
        }
        if (index == 4) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Vet()),
          );
        }
        if (index == 5) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Profile()),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: "Logs"),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Health"),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
        BottomNavigationBarItem(icon: Icon(Icons.location_city), label: "Vet"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}
