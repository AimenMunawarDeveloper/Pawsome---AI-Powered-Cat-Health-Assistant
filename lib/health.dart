import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'chat.dart';
import 'home.dart';
import 'login.dart';
import 'logs.dart';
import 'profile.dart';
import 'profile_data_service.dart';
import 'vet.dart';

class Health extends StatefulWidget {
  const Health({super.key});

  @override
  State<Health> createState() => _HealthState();
}

class _HealthState extends State<Health> {
  final ProfileDataService _profileDataService = ProfileDataService();

  Future<void> _disposeControllersLater(
    List<TextEditingController> controllers,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    for (final controller in controllers) {
      controller.dispose();
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

  Map<String, dynamic> _healthData(Map<String, dynamic> profileData) {
    return Map<String, dynamic>.from(
      profileData['health'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> _petData(Map<String, dynamic> profileData) {
    return Map<String, dynamic>.from(
      profileData['pet'] as Map<String, dynamic>? ?? {},
    );
  }

  List<Map<String, String>> _vaccinations(Map<String, dynamic> healthData) {
    return (healthData['vaccinations'] as List<dynamic>? ?? const <dynamic>[])
        .map((entry) => Map<String, String>.from(entry as Map))
        .toList();
  }

  List<String> _allergies(Map<String, dynamic> healthData) {
    return List<String>.from(
      healthData['allergies'] as List<dynamic>? ?? const <dynamic>[],
    );
  }

  bool _hasHealthSummary(Map<String, dynamic> healthData) {
    return (healthData['vetName'] as String? ?? '').trim().isNotEmpty ||
        (healthData['vetPhone'] as String? ?? '').trim().isNotEmpty ||
        (healthData['lastVisit'] as String? ?? '').trim().isNotEmpty ||
        (healthData['lastWeight'] as String? ?? '').trim().isNotEmpty;
  }

  Future<void> _showHealthSummaryEditor(Map<String, dynamic> profileData) async {
    final healthData = _healthData(profileData);
    final petData = _petData(profileData);

    final vetNameController = TextEditingController(
      text: healthData['vetName'] as String? ?? '',
    );
    final vetPhoneController = TextEditingController(
      text: healthData['vetPhone'] as String? ?? '',
    );
    final lastVisitController = TextEditingController(
      text: healthData['lastVisit'] as String? ?? '',
    );
    final lastWeightController = TextEditingController(
      text: (healthData['lastWeight'] as String?)?.trim().isNotEmpty == true
          ? healthData['lastWeight'] as String
          : petData['weight'] as String? ?? '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            Future<void> saveSummary() async {
              final navigator = Navigator.of(bottomSheetContext);
              var didCloseSheet = false;

              setModalState(() => isSaving = true);
              try {
                await _profileDataService.updateHealthSummary(
                  vetName: vetNameController.text.trim(),
                  vetPhone: vetPhoneController.text.trim(),
                  lastVisit: lastVisitController.text.trim(),
                  lastWeight: lastWeightController.text.trim(),
                );
                if (!mounted) return;
                didCloseSheet = true;
                navigator.pop();
                _showMessage('Health summary updated.');
              } catch (_) {
                _showMessage('Could not save health details.');
              } finally {
                if (!didCloseSheet && modalContext.mounted) {
                  setModalState(() => isSaving = false);
                }
              }
            }

            return _buildEditorSheet(
              title: 'Update Health Details',
              child: Column(
                children: [
                  _buildTextField(
                    controller: vetNameController,
                    label: 'Veterinarian Name',
                    textInputAction: TextInputAction.next,
                  ),
                  _buildTextField(
                    controller: vetPhoneController,
                    label: 'Veterinarian Phone',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  _buildTextField(
                    controller: lastVisitController,
                    label: 'Last Visit',
                    helperText: 'Example: 19/04/2026',
                    textInputAction: TextInputAction.next,
                  ),
                  _buildTextField(
                    controller: lastWeightController,
                    label: 'Last Weight',
                    helperText: 'Example: 4.2 kg',
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 8),
                  _buildSaveButton(isSaving: isSaving, onTap: saveSummary),
                ],
              ),
            );
          },
        );
      },
    );

    await _disposeControllersLater([
      vetNameController,
      vetPhoneController,
      lastVisitController,
      lastWeightController,
    ]);
  }

  Future<void> _showVaccinationEditor() async {
    final nameController = TextEditingController();
    final dateController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            Future<void> saveVaccination() async {
              final navigator = Navigator.of(bottomSheetContext);
              var didCloseSheet = false;

              if (nameController.text.trim().isEmpty ||
                  dateController.text.trim().isEmpty) {
                _showMessage('Please add both a vaccine name and date.');
                return;
              }

              setModalState(() => isSaving = true);
              try {
                await _profileDataService.addVaccination(
                  name: nameController.text.trim(),
                  date: dateController.text.trim(),
                );
                if (!mounted) return;
                didCloseSheet = true;
                navigator.pop();
                _showMessage('Vaccination added.');
              } catch (_) {
                _showMessage('Could not add vaccination.');
              } finally {
                if (!didCloseSheet && modalContext.mounted) {
                  setModalState(() => isSaving = false);
                }
              }
            }

            return _buildEditorSheet(
              title: 'Add Vaccination',
              child: Column(
                children: [
                  _buildTextField(
                    controller: nameController,
                    label: 'Vaccination Name',
                    textInputAction: TextInputAction.next,
                  ),
                  _buildTextField(
                    controller: dateController,
                    label: 'Date',
                    helperText: 'Example: 19/04/2026',
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 8),
                  _buildSaveButton(
                    isSaving: isSaving,
                    onTap: saveVaccination,
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    await _disposeControllersLater([nameController, dateController]);
  }

  Future<void> _showAllergyEditor() async {
    final allergyController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            Future<void> saveAllergy() async {
              final navigator = Navigator.of(bottomSheetContext);
              var didCloseSheet = false;

              if (allergyController.text.trim().isEmpty) {
                _showMessage('Please enter an allergy or sensitivity.');
                return;
              }

              setModalState(() => isSaving = true);
              try {
                await _profileDataService.addAllergy(
                  allergyController.text.trim(),
                );
                if (!mounted) return;
                didCloseSheet = true;
                navigator.pop();
                _showMessage('Allergy added.');
              } catch (_) {
                _showMessage('Could not add allergy.');
              } finally {
                if (!didCloseSheet && modalContext.mounted) {
                  setModalState(() => isSaving = false);
                }
              }
            }

            return _buildEditorSheet(
              title: 'Add Allergy',
              child: Column(
                children: [
                  _buildTextField(
                    controller: allergyController,
                    label: 'Allergy or Sensitivity',
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 8),
                  _buildSaveButton(isSaving: isSaving, onTap: saveAllergy),
                ],
              ),
            );
          },
        );
      },
    );

    await _disposeControllersLater([allergyController]);
  }

  Future<void> _removeVaccination(int index) async {
    try {
      await _profileDataService.removeVaccinationAt(index);
      _showMessage('Vaccination removed.');
    } catch (_) {
      _showMessage('Could not remove vaccination.');
    }
  }

  Future<void> _removeAllergy(int index) async {
    try {
      await _profileDataService.removeAllergyAt(index);
      _showMessage('Allergy removed.');
    } catch (_) {
      _showMessage('Could not remove allergy.');
    }
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
                Navigator.pushReplacement(context, _createRoute(const Profile()));
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

  Widget _buildHeader(Map<String, dynamic> profileData) {
    final petData = _petData(profileData);
    final petName = _valueOrFallback(
      petData['name'] as String?,
      fallback: 'Your Cat',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$petName's Health Profile",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "View all the records related to your pet's health.",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Image.asset('assets/images/doctor.png', height: 160),
        ],
      ),
    );
  }

  Widget _buildVetCard(Map<String, dynamic> profileData) {
    final healthData = _healthData(profileData);
    final vetName = (healthData['vetName'] as String? ?? '').trim();
    final vetPhone = (healthData['vetPhone'] as String? ?? '').trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondarySoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Veterinarian',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton(
                  onPressed: () => _showHealthSummaryEditor(profileData),
                  child: Text(vetName.isEmpty ? 'Add' : 'Edit'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              vetName.isEmpty ? 'No veterinarian added yet.' : vetName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    vetPhone.isEmpty ? 'Add a phone number for your vet.' : vetPhone,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required IconData icon,
    required String value,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: AppColors.surface)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: AppColors.surface),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.surface),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.surface),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitWeightCards(Map<String, dynamic> profileData) {
    final healthData = _healthData(profileData);
    final petData = _petData(profileData);

    final lastVisit = _valueOrFallback(healthData['lastVisit'] as String?);
    final lastWeight = _valueOrFallback(
      (healthData['lastWeight'] as String?)?.trim().isNotEmpty == true
          ? healthData['lastWeight'] as String
          : petData['weight'] as String?,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildMetricCard(
            title: 'Last Visit',
            icon: Icons.calendar_today,
            value: lastVisit,
            actionLabel: lastVisit == 'Not added yet' ? 'Add Visit' : 'Edit',
            onTap: () => _showHealthSummaryEditor(profileData),
          ),
          const SizedBox(width: 15),
          _buildMetricCard(
            title: 'Last Weight',
            icon: Icons.monitor_weight,
            value: lastWeight,
            actionLabel: lastWeight == 'Not added yet' ? 'Add Weight' : 'Edit',
            onTap: () => _showHealthSummaryEditor(profileData),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinationSection(Map<String, dynamic> profileData) {
    final vaccinations = _vaccinations(_healthData(profileData));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vaccination Records',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _AddButton(onTap: _showVaccinationEditor),
            ],
          ),
          const SizedBox(height: 10),
          if (vaccinations.isEmpty)
            _buildEmptySectionCard(
              title: 'No vaccinations added yet.',
              actionLabel: 'Add Vaccination',
              onTap: _showVaccinationEditor,
            )
          else
            ...vaccinations.asMap().entries.map((entry) {
              final index = entry.key;
              final vaccine = entry.value;
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.vaccines,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _valueOrFallback(
                            vaccine['name'],
                            fallback: 'Unnamed vaccination',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _valueOrFallback(
                          vaccine['date'],
                          fallback: 'No date',
                        ),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      IconButton(
                        onPressed: () => _removeVaccination(index),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Remove vaccination',
                      ),
                    ],
                  ),
                  const Divider(),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAllergySection(Map<String, dynamic> profileData) {
    final allergies = _allergies(_healthData(profileData));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Allergies & Sensitivities",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _AddButton(onTap: _showAllergyEditor),
            ],
          ),
          const SizedBox(height: 10),
          if (allergies.isEmpty)
            _buildEmptySectionCard(
              title: 'No allergies added yet.',
              actionLabel: 'Add Allergy',
              onTap: _showAllergyEditor,
            )
          else
            ...allergies.asMap().entries.map((entry) {
              final index = entry.key;
              final allergy = entry.value;
              return Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.radio_button_checked,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(allergy)),
                      IconButton(
                        onPressed: () => _removeAllergy(index),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Remove allergy',
                      ),
                    ],
                  ),
                  const Divider(),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptySectionCard({
    required String title,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
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
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          filled: true,
          fillColor: AppColors.backgroundAlt,
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

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Could not load health data right now.',
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
          'Please sign in to view your pet health profile.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildHealthContent(Map<String, dynamic> profileData) {
    final healthData = _healthData(profileData);

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildAppBar(),
            const SizedBox(height: 20),
            _buildHeader(profileData),
            const SizedBox(height: 20),
            _buildVetCard(profileData),
            if (!_hasHealthSummary(healthData))
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _buildEmptySectionCard(
                  title: 'Add your vet, last visit, and latest weight to start tracking health information.',
                  actionLabel: 'Add Health Details',
                  onTap: () => _showHealthSummaryEditor(profileData),
                ),
              ),
            const SizedBox(height: 15),
            _buildVisitWeightCards(profileData),
            const SizedBox(height: 20),
            _buildVaccinationSection(profileData),
            const SizedBox(height: 20),
            _buildAllergySection(profileData),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 2,
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
                return _buildHealthContent(profileData);
              },
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
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
