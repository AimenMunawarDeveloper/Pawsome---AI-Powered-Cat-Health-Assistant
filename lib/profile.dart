import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'chat.dart';
import 'health.dart';
import 'home.dart';
import 'login.dart';
import 'logs.dart';
import 'profile_data_service.dart';
import 'vet.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final ProfileDataService _profileDataService = ProfileDataService();

  Future<void> _disposeControllersLater(
    List<TextEditingController> controllers,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    for (final controller in controllers) {
      controller.dispose();
    }
  }

  @override
  void initState() {
    super.initState();
    _ensureProfileExists();
  }

  Future<void> _ensureProfileExists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _profileDataService.createProfileIfMissing(
        name: user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : 'Pet Parent',
        email: user.email ?? '',
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showMessage(
        error.code == 'unavailable'
            ? 'Could not connect to Firestore right now. Check your Firebase setup and internet connection.'
            : 'Could not load your profile data right now.',
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not load your profile data right now.');
    }
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

  String _valueOrFallback(String? value, {String fallback = 'Not added yet'}) {
    final cleaned = value?.trim() ?? '';
    return cleaned.isEmpty ? fallback : cleaned;
  }

  Map<String, String> _guardianFields(Map<String, dynamic> profileData) {
    final user = FirebaseAuth.instance.currentUser;
    final guardian = Map<String, dynamic>.from(
      profileData['guardian'] as Map<String, dynamic>? ?? {},
    );

    return {
      'Name': _valueOrFallback(
        guardian['name'] as String? ?? user?.displayName,
        fallback: 'Pet Parent',
      ),
      'Email': _valueOrFallback(
        guardian['email'] as String? ?? user?.email,
        fallback: 'No email found',
      ),
      'Contact no.': _valueOrFallback(guardian['contactNo'] as String?),
      'Address': _valueOrFallback(guardian['address'] as String?),
      'Emergency no.': _valueOrFallback(guardian['emergencyNo'] as String?),
    };
  }

  Map<String, String> _petFields(Map<String, dynamic> profileData) {
    final pet = Map<String, dynamic>.from(
      profileData['pet'] as Map<String, dynamic>? ?? {},
    );

    return {
      'Name': _valueOrFallback(pet['name'] as String?),
      'Breed': _valueOrFallback(pet['breed'] as String?),
      'Age': _valueOrFallback(pet['age'] as String?),
      'Gender': _valueOrFallback(pet['gender'] as String?),
      'Weight': _valueOrFallback(pet['weight'] as String?),
    };
  }

  Future<void> _showGuardianEditor(Map<String, dynamic> profileData) async {
    final user = FirebaseAuth.instance.currentUser;
    final guardian = Map<String, dynamic>.from(
      profileData['guardian'] as Map<String, dynamic>? ?? {},
    );

    final nameController = TextEditingController(
      text: guardian['name'] as String? ?? user?.displayName ?? '',
    );
    final emailController = TextEditingController(
      text: guardian['email'] as String? ?? user?.email ?? '',
    );
    final contactController = TextEditingController(
      text: guardian['contactNo'] as String? ?? '',
    );
    final addressController = TextEditingController(
      text: guardian['address'] as String? ?? '',
    );
    final emergencyController = TextEditingController(
      text: guardian['emergencyNo'] as String? ?? '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> saveGuardian() async {
              final navigator = Navigator.of(context);
              var didCloseSheet = false;

              if (nameController.text.trim().isEmpty) {
                _showMessage('Please enter your name.');
                return;
              }

              setModalState(() => isSaving = true);
              try {
                await _profileDataService.updateGuardian(
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  contactNo: contactController.text.trim(),
                  address: addressController.text.trim(),
                  emergencyNo: emergencyController.text.trim(),
                );
                if (!mounted) return;
                didCloseSheet = true;
                navigator.pop();
                _showMessage('Guardian details updated.');
              } catch (_) {
                _showMessage('Could not save guardian details.');
              } finally {
                if (!didCloseSheet && context.mounted) {
                  setModalState(() => isSaving = false);
                }
              }
            }

            return _buildEditorSheet(
              title: 'Edit Guardian Details',
              child: Column(
                children: [
                  _buildTextField(
                    controller: nameController,
                    label: 'Name',
                    textInputAction: TextInputAction.next,
                  ),
                  _buildTextField(
                    controller: emailController,
                    label: 'Email',
                    enabled: false,
                    helperText: 'Email comes from your login account for now.',
                  ),
                  _buildTextField(
                    controller: contactController,
                    label: 'Contact Number',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  _buildTextField(
                    controller: addressController,
                    label: 'Address',
                    textInputAction: TextInputAction.next,
                  ),
                  _buildTextField(
                    controller: emergencyController,
                    label: 'Emergency Number',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 8),
                  _buildSaveButton(isSaving: isSaving, onTap: saveGuardian),
                ],
              ),
            );
          },
        );
      },
    );

    await _disposeControllersLater([
      nameController,
      emailController,
      contactController,
      addressController,
      emergencyController,
    ]);
  }

  Future<void> _showPetEditor(Map<String, dynamic> profileData) async {
    final pet = Map<String, dynamic>.from(
      profileData['pet'] as Map<String, dynamic>? ?? {},
    );

    final nameController = TextEditingController(text: pet['name'] as String? ?? '');
    final breedController = TextEditingController(
      text: pet['breed'] as String? ?? '',
    );
    final ageController = TextEditingController(text: pet['age'] as String? ?? '');
    final genderController = TextEditingController(
      text: pet['gender'] as String? ?? '',
    );
    final weightController = TextEditingController(
      text: pet['weight'] as String? ?? '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> savePet() async {
              final navigator = Navigator.of(context);
              var didCloseSheet = false;

              if (nameController.text.trim().isEmpty) {
                _showMessage('Please enter your cat name.');
                return;
              }

              setModalState(() => isSaving = true);
              try {
                await _profileDataService.updatePet(
                  name: nameController.text.trim(),
                  breed: breedController.text.trim(),
                  age: ageController.text.trim(),
                  gender: genderController.text.trim(),
                  weight: weightController.text.trim(),
                );
                if (!mounted) return;
                didCloseSheet = true;
                navigator.pop();
                _showMessage('Cat details updated.');
              } catch (_) {
                _showMessage('Could not save cat details.');
              } finally {
                if (!didCloseSheet && context.mounted) {
                  setModalState(() => isSaving = false);
                }
              }
            }

            return _buildEditorSheet(
              title: 'Edit Cat Details',
              child: Column(
                children: [
                  _buildTextField(
                    controller: nameController,
                    label: 'Cat Name',
                    textInputAction: TextInputAction.next,
                  ),
                  _buildTextField(
                    controller: breedController,
                    label: 'Breed',
                    textInputAction: TextInputAction.next,
                  ),
                  _buildTextField(
                    controller: ageController,
                    label: 'Age',
                    textInputAction: TextInputAction.next,
                  ),
                  _buildTextField(
                    controller: genderController,
                    label: 'Gender',
                    textInputAction: TextInputAction.next,
                  ),
                  _buildTextField(
                    controller: weightController,
                    label: 'Weight',
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 8),
                  _buildSaveButton(isSaving: isSaving, onTap: savePet),
                ],
              ),
            );
          },
        );
      },
    );

    await _disposeControllersLater([
      nameController,
      breedController,
      ageController,
      genderController,
      weightController,
    ]);
  }

  Widget _buildEditorSheet({required String title, required Widget child}) {
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool enabled = true,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          filled: true,
          fillColor: enabled ? AppColors.backgroundAlt : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton({
    required bool isSaving,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSaving ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : const Text('Save'),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                Navigator.pushReplacement(context, _createRoute(const Health()));
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

  Widget _buildProfileHeader(Map<String, String> petFields) {
    final petName = petFields['Name'] ?? 'Your Cat';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$petName\'s Profile',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Keep your account and cat information updated in one place.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Hero(
            tag: 'cat_profile',
            child: const CircleAvatar(
              radius: 45,
              backgroundImage: AssetImage('assets/images/catprofile.png'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required Map<String, String> fields,
    required VoidCallback onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
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
                _EditButton(onTap: onEdit),
              ],
            ),
            const SizedBox(height: 15),
            ...fields.entries.map((entry) {
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          entry.value,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(Map<String, dynamic> profileData) {
    final petFields = _petFields(profileData);
    final guardianFields = _guardianFields(profileData);

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildAppBar(),
            const SizedBox(height: 20),
            _buildProfileHeader(petFields),
            const SizedBox(height: 20),
            _buildCard(
              title: 'Cat Details',
              fields: petFields,
              onEdit: () => _showPetEditor(profileData),
            ),
            const SizedBox(height: 20),
            _buildCard(
              title: 'Guardian Details',
              fields: guardianFields,
              onEdit: () => _showGuardianEditor(profileData),
            ),
            const SizedBox(height: 30),
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
          'Could not load profile data right now.',
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
          'Please sign in to view your profile.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 5,
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
      backgroundColor: AppColors.backgroundAlt,
      drawer: _buildDrawer(),
      body: user == null
          ? _buildSignedOutState()
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _profileDataService.profileStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState();
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return _buildLoadingState();
                }

                final profileData = snapshot.data?.data() ?? <String, dynamic>{};
                return _buildProfileContent(profileData);
              },
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}

class _EditButton extends StatefulWidget {
  const _EditButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_EditButton> createState() => _EditButtonState();
}

class _EditButtonState extends State<_EditButton> {
  double scale = 1.0;

  Future<void> _animateTap() async {
    setState(() => scale = 0.85);
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('Edit', style: TextStyle(color: AppColors.surface)),
        ),
      ),
    );
  }
}
