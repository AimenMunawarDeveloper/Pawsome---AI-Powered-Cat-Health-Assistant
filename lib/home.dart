import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import "chat.dart";
import "profile.dart";
import "logs.dart";
import "health.dart";
import "vet.dart";
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'login.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  List<bool> dailyChecked = [false, false, false, false];
  List<bool> extraChecked = [false, false, false, false];
  bool animateText = false;
  final GlobalKey _tipsKey = GlobalKey();
  bool hasAnimated = false;
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  final ScrollController _scrollController = ScrollController();
  Widget _animatedAddButton(VoidCallback onTap) {
    return _AddButton(onTap: onTap);
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
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        animateText = true;
      });
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scrollController.addListener(() {
      if (hasAnimated) return;

      final context = _tipsKey.currentContext;
      if (context != null) {
        final box = context.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero);

        final screenHeight = MediaQuery.of(context).size.height;

        if (position.dy < screenHeight * 0.8) {
          hasAnimated = true;
          _controller.forward(from: 0);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(),
              _buildHeaderSection(),
              const SizedBox(height: 20),
              _buildDailyTasks(),
              const SizedBox(height: 20),
              _buildExtraActivities(),
              const SizedBox(height: 20),
              _buildRecommendedSection(),
              const SizedBox(height: 20),
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

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Plan Mimi’s day!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "A cute way to plan your cat’s activities and make every day more purr-fect.",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const Profile(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                ),
              );
            },
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const Profile(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          const begin = 0.0;
                          const end = 1.0;
                          const curve = Curves.easeInOutCubic;

                          var fadeAnimation = Tween(
                            begin: begin,
                            end: end,
                          ).chain(CurveTween(curve: curve)).animate(animation);

                          var scaleAnimation = Tween(
                            begin: 0.8,
                            end: 1.0,
                          ).chain(CurveTween(curve: curve)).animate(animation);

                          return FadeTransition(
                            opacity: fadeAnimation,
                            child: ScaleTransition(
                              scale: scaleAnimation,
                              child: child,
                            ),
                          );
                        },
                    transitionDuration: const Duration(milliseconds: 600),
                  ),
                );
              },
              child: Hero(
                tag: 'cat_profile',
                flightShuttleBuilder:
                    (
                      flightContext,
                      animation,
                      direction,
                      fromContext,
                      toContext,
                    ) {
                      return Transform.scale(
                        scale: animation.value * 1.2,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(
                                  0.5 * (1 - animation.value),
                                ),
                                blurRadius: 20 * (1 - animation.value),
                                spreadRadius: 5 * (1 - animation.value),
                              ),
                            ],
                          ),
                          child: const CircleAvatar(
                            radius: 45,
                            backgroundImage: AssetImage(
                              "assets/images/catprofile.png",
                            ),
                          ),
                        ),
                      );
                    },
                child: const CircleAvatar(
                  radius: 45,
                  backgroundImage: AssetImage("assets/images/catprofile.png"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTasks() {
    return _buildTaskCard(
      title: "Daily Healthy tasks",
      items: const ["Brush teeth", "Eaten food", "Drank Water", "Played"],
      checkedList: dailyChecked,
      icon: Icons.check_circle_outline,
      color: AppColors.primary,
    );
  }

  Widget _buildExtraActivities() {
    return _buildTaskCard(
      title: "Extra Activities",
      items: const ["Go for walk", "Eaten Treats", "Bath", "Vaccination"],
      checkedList: extraChecked,
      icon: Icons.star_border,
      color: AppColors.secondary,
    );
  }

  Widget _buildTaskCard({
    required String title,
    required List<String> items,
    required List<bool> checkedList,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _animatedAddButton(() {}),
              ],
            ),

            const SizedBox(height: 10),
            ...List.generate(items.length, (index) {
              final isChecked = checkedList[index];

              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: isChecked ? 10 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: isChecked
                          ? color.withOpacity(0.20)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          scale: isChecked ? 1.1 : 1.0,
                          child: Icon(icon, color: color, size: 20),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                              fontSize: 14,
                              color: isChecked
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              decoration: isChecked
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                            child: Text(items[index]),
                          ),
                        ),
                        AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          scale: isChecked ? 1.1 : 1.0,
                          child: Checkbox(
                            value: isChecked,
                            onChanged: (value) {
                              setState(() {
                                checkedList[index] = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedSection() {
    final tips = [
      {"img": "assets/images/tip1.png", "title": "Top 10 Ways to Wash Cat"},
      {"img": "assets/images/tip2.png", "title": "Why is My Cat Sad?"},
      {"img": "assets/images/tip1.png", "title": "Healthy Cat Diet"},
      {"img": "assets/images/tip2.png", "title": "Cat Sleep Guide"},
    ];

    return Padding(
      key: _tipsKey,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recommended Tips",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tips.length,
              itemBuilder: (context, index) {
                final start = index * 0.2;
                final end = start + 0.6;

                final curvedAnimation = CurvedAnimation(
                  parent: _controller,
                  curve: Interval(
                    start,
                    end > 1 ? 1 : end,
                    curve: Curves.easeOut,
                  ),
                );

                final animation = Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(curvedAnimation);

                return SlideTransition(
                  position: animation,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SizedBox(
                      width: 160,
                      child: _buildTipCard(
                        tips[index]["img"]!,
                        tips[index]["title"]!,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(String image, String title) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(image, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 0,
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

class _AddButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  double scale = 1.0;

  void _animateTap() async {
    setState(() => scale = 0.7);

    await Future.delayed(const Duration(milliseconds: 100));

    setState(() => scale = 1.0);

    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _animateTap,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: const CircleAvatar(
          backgroundColor: AppColors.secondaryDark,
          radius: 14,
          child: Icon(Icons.add, size: 16, color: AppColors.surface),
        ),
      ),
    );
  }
}
