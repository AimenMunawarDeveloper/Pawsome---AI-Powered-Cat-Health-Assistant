import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import "chat.dart";
import "profile.dart";
import "home.dart";
import "health.dart";
import "vet.dart";
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'login.dart';

class Logs extends StatefulWidget {
  const Logs({super.key});
  @override
  State<Logs> createState() => _LogsState();
}

class _LogsState extends State<Logs> with TickerProviderStateMixin {
  late AnimationController _healthController;
  late AnimationController _stressController;

  late Animation<Offset> _healthSlide;
  late Animation<Offset> _stressSlide;

  @override
  void initState() {
    super.initState();

    _healthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _stressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _healthSlide = Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _healthController, curve: Curves.easeOut),
        );

    _stressSlide = Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _stressController, curve: Curves.easeOut),
        );

    // Start animations
    _healthController.forward();

    Future.delayed(const Duration(milliseconds: 200), () {
      _stressController.forward();
    });
  }

  @override
  void dispose() {
    _healthController.dispose();
    _stressController.dispose();
    super.dispose();
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;

        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: Curves.easeOut));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildAppBar(),
              const SizedBox(height: 20),
              _buildCalendarSection(),
              const SizedBox(height: 20),
              _buildConcernCard(),
              const SizedBox(height: 20),
              _buildCareLogsCard(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
      (route) => false,
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      color: AppColors.primary,
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
                  color: AppColors.surface,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.notifications_none, color: AppColors.surface),
              IconButton(
                onPressed: _signOut,
                icon: const Icon(Icons.logout, color: AppColors.surface),
                tooltip: 'Sign out',
              ),
            ],
          ),
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
                Navigator.pushReplacement(context, _createRoute(const Home()));
              }),
              _drawerItem(Icons.list_alt, "Logs", () {
                Navigator.pushReplacement(context, _createRoute(const Logs()));
              }),
              _drawerItem(Icons.favorite, "Health", () {
                Navigator.pushReplacement(
                  context,
                  _createRoute(const Health()),
                );
              }),
              _drawerItem(Icons.auto_awesome, "AI Chat", () {
                Navigator.pushReplacement(context, _createRoute(const Chat()));
              }),
              _drawerItem(Icons.location_on, "Vet Locator", () {
                Navigator.pushReplacement(context, _createRoute(const Vet()));
              }),
              _drawerItem(Icons.person, "Profile", () {
                Navigator.pushReplacement(
                  context,
                  _createRoute(const Profile()),
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

  Widget _buildCalendarSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Text(
              "2/2026",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 15),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 28,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                ValueNotifier<bool> isHovered = ValueNotifier(false);

                return MouseRegion(
                  onEnter: (_) => isHovered.value = true,
                  onExit: (_) => isHovered.value = false,
                  child: ValueListenableBuilder(
                    valueListenable: isHovered,
                    builder: (context, hovered, child) {
                      return AnimatedScale(
                        scale: hovered ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: hovered
                                ? AppColors.primaryDark
                                : AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConcernCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondaryDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "😿 Concern",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Score: 50     Health: 5/10     Stress: 5/10",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),

            const Text("Health", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 5),

            AnimatedBuilder(
              animation: _healthController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _healthController.value * 0.5, // animates from 0 → 0.5
                  backgroundColor: AppColors.surface,
                  color: AppColors.primarySoft,
                );
              },
            ),

            const SizedBox(height: 10),

            const Text("Stress", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 5),
            AnimatedBuilder(
              animation: _stressController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _stressController.value * 0.5,
                  backgroundColor: AppColors.surface,
                  color: AppColors.primarySoft,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareLogsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📋 Care Logs",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "🐱 Mimi  7/10",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text("Condition: Good 🙂     Appetite: Great 😋"),
                  SizedBox(height: 5),
                  Text("Bowl: Diarrhea 💩     Urination: More than Usual 🚿"),
                  SizedBox(height: 5),
                  Text("Weight: 2.5 kg"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 1,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.primary,
      selectedItemColor: AppColors.navSelected,
      unselectedItemColor: AppColors.surface,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacement(context, _createRoute(const Home()));
        }
        if (index == 1) {
          Navigator.pushReplacement(context, _createRoute(const Logs()));
        }
        if (index == 2) {
          Navigator.pushReplacement(context, _createRoute(const Health()));
        }
        if (index == 3) {
          Navigator.pushReplacement(context, _createRoute(const Chat()));
        }
        if (index == 4) {
          Navigator.pushReplacement(context, _createRoute(const Vet()));
        }
        if (index == 5) {
          Navigator.pushReplacement(context, _createRoute(const Profile()));
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
