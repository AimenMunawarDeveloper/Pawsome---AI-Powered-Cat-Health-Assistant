import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'chat.dart';
import 'health.dart';
import 'login.dart';
import 'logs.dart';
import 'profile.dart';
import 'profile_data_service.dart';
import 'vet.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  final GlobalKey _tipsKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  final ProfileDataService _profileDataService = ProfileDataService();

  bool hasAnimated = false;
  late AnimationController _controller;
  late Future<_HomeViewData> _homeDataFuture;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scrollController.addListener(() {
      if (hasAnimated) return;

      final tipsContext = _tipsKey.currentContext;
      if (tipsContext == null) return;

      final box = tipsContext.findRenderObject() as RenderBox?;
      if (box == null) return;

      final position = box.localToGlobal(Offset.zero);
      final screenHeight = MediaQuery.of(context).size.height;

      if (position.dy < screenHeight * 0.8) {
        hasAnimated = true;
        _controller.forward(from: 0);
      }
    });

    _homeDataFuture = _loadHomeData();
  }

  Future<_HomeViewData> _loadHomeData() async {
    await _profileDataService.ensureHomeData();
    final results = await Future.wait<dynamic>([
      _profileDataService.getProfileData(),
      _profileDataService.getRecommendations(),
    ]);

    return _HomeViewData(
      profileData: results[0] as Map<String, dynamic>,
      recommendations: (results[1] as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(),
    );
  }

  Future<void> _reloadHomeData() async {
    if (!mounted) return;
    setState(() {
      _homeDataFuture = _loadHomeData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
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

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
      (route) => false,
    );
  }

  Map<String, dynamic> _petData(Map<String, dynamic> profileData) {
    return Map<String, dynamic>.from(
      profileData['pet'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> _homeData(Map<String, dynamic> profileData) {
    return Map<String, dynamic>.from(
      profileData['home'] as Map<String, dynamic>? ?? {},
    );
  }

  String _valueOrFallback(String? value, {String fallback = 'Your Cat'}) {
    final cleaned = value?.trim() ?? '';
    return cleaned.isEmpty ? fallback : cleaned;
  }

  List<Map<String, dynamic>> _taskList(
    Map<String, dynamic> profileData,
    String section,
  ) {
    final home = _homeData(profileData);
    return (home[section] as List<dynamic>? ?? const <dynamic>[])
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showAddTaskSheet({
    required String title,
    required String section,
  }) async {
    final controller = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            Future<void> saveTask() async {
              final navigator = Navigator.of(bottomSheetContext);
              var didCloseSheet = false;

              if (controller.text.trim().isEmpty) {
                _showMessage('Please enter a task name.');
                return;
              }

              setModalState(() => isSaving = true);
              try {
                await _profileDataService.addHomeTask(
                  section: section,
                  title: controller.text.trim(),
                );
                await _reloadHomeData();
                if (!mounted) return;
                didCloseSheet = true;
                navigator.pop();
                _showMessage('$title task added.');
              } catch (_) {
                _showMessage('Could not add task.');
              } finally {
                if (!didCloseSheet && modalContext.mounted) {
                  setModalState(() => isSaving = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add $title Task',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'Task name',
                        filled: true,
                        fillColor: AppColors.backgroundAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : saveTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
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
              Image.asset('assets/images/logo.png', height: 28, width: 28),
              const SizedBox(width: 8),
              Text(
                'Pawsome',
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
              _drawerItem(Icons.home, 'Home', () {
                Navigator.pushReplacement(context, _createRoute(const Home()));
              }),
              _drawerItem(Icons.list_alt, 'Logs', () {
                Navigator.pushReplacement(context, _createRoute(const Logs()));
              }),
              _drawerItem(Icons.favorite, 'Health', () {
                Navigator.pushReplacement(
                  context,
                  _createRoute(const Health()),
                );
              }),
              _drawerItem(Icons.auto_awesome, 'AI Chat', () {
                Navigator.pushReplacement(context, _createRoute(const Chat()));
              }),
              _drawerItem(Icons.location_on, 'Vet Locator', () {
                Navigator.pushReplacement(context, _createRoute(const Vet()));
              }),
              _drawerItem(Icons.person, 'Profile', () {
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

  Widget _buildHeaderSection(Map<String, dynamic> profileData) {
    final petName = _valueOrFallback(_petData(profileData)['name'] as String?);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Plan $petName's day!",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "A cute way to plan your cat's activities and make every day more purr-fect.",
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
            child: Hero(
              tag: 'cat_profile',
              child: const CircleAvatar(
                radius: 45,
                backgroundImage: AssetImage('assets/images/catprofile.png'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTasks(Map<String, dynamic> profileData) {
    return _buildTaskCard(
      title: 'Daily Healthy tasks',
      section: 'dailyTasks',
      tasks: _taskList(profileData, 'dailyTasks'),
      icon: Icons.check_circle_outline,
      color: AppColors.primary,
    );
  }

  Widget _buildExtraActivities(Map<String, dynamic> profileData) {
    return _buildTaskCard(
      title: 'Extra Activities',
      section: 'extraActivities',
      tasks: _taskList(profileData, 'extraActivities'),
      icon: Icons.star_border,
      color: AppColors.secondary,
    );
  }

  Widget _buildTaskCard({
    required String title,
    required String section,
    required List<Map<String, dynamic>> tasks,
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
                _AddButton(
                  onTap: () =>
                      _showAddTaskSheet(title: title, section: section),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No tasks added yet.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ...List.generate(tasks.length, (index) {
              final task = tasks[index];
              final isChecked = task['done'] as bool? ?? false;
              final taskTitle = task['title'] as String? ?? 'Untitled task';

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
                          ? color.withValues(alpha: 0.20)
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
                            child: Text(taskTitle),
                          ),
                        ),
                        AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          scale: isChecked ? 1.1 : 1.0,
                          child: Checkbox(
                            value: isChecked,
                            onChanged: (value) async {
                              if (value == null) return;
                              try {
                                await _profileDataService.updateHomeTaskStatus(
                                  section: section,
                                  index: index,
                                  done: value,
                                );
                                await _reloadHomeData();
                              } catch (_) {
                                _showMessage('Could not update task.');
                              }
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

  Widget _buildRecommendedSection(List<Map<String, dynamic>> tips) {
    return Padding(
      key: _tipsKey,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended Tips',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: tips.isEmpty
                ? const Center(
                    child: Text(
                      'No recommendations available yet.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: tips.length,
                    itemBuilder: (context, index) {
                      final tip = tips[index];
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
                              tip['image'] as String? ??
                                  'assets/images/tip1.png',
                              tip['title'] as String? ?? 'Helpful tip',
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
    final imageWidget =
        image.startsWith('http://') || image.startsWith('https://')
        ? Image.network(
            image,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.secondarySoft,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.textSecondary,
                  size: 34,
                ),
              );
            },
          )
        : Image.asset(
            image,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.secondarySoft,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.textSecondary,
                  size: 34,
                ),
              );
            },
          );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(aspectRatio: 16 / 9, child: imageWidget),
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

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Could not load home data right now.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSignedOutState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Please sign in to view your home dashboard.',
          textAlign: TextAlign.center,
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
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Logs'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Health'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.location_city), label: 'Vet'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(),
      body: user == null
          ? _buildSignedOutState()
          : FutureBuilder<_HomeViewData>(
              future: _homeDataFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState();
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return _buildLoadingState();
                }

                final data = snapshot.data;
                if (data == null) {
                  return _buildErrorState();
                }

                return SafeArea(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAppBar(),
                        _buildHeaderSection(data.profileData),
                        const SizedBox(height: 20),
                        _buildDailyTasks(data.profileData),
                        const SizedBox(height: 20),
                        _buildExtraActivities(data.profileData),
                        const SizedBox(height: 20),
                        _buildRecommendedSection(data.recommendations),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}

class _HomeViewData {
  const _HomeViewData({
    required this.profileData,
    required this.recommendations,
  });

  final Map<String, dynamic> profileData;
  final List<Map<String, dynamic>> recommendations;
}

class _AddButton extends StatefulWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  double scale = 1.0;

  Future<void> _animateTap() async {
    setState(() => scale = 0.7);
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
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
