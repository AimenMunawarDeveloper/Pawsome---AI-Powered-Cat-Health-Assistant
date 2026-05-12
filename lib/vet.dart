import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import "chat.dart";
import "profile.dart";
import "logs.dart";
import "health.dart";
import "home.dart";
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'login.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class Vet extends StatefulWidget {
  const Vet({super.key});

  @override
  State<Vet> createState() => _VetState();
}

class _VetState extends State<Vet> {
  /// Same center as [MapOptions.initialCenter] so the search matches the map.
  static const LatLng _mapCenter = LatLng(33.6844, 73.0479);

  /// Overpass `around:` radius in meters — a fixed bbox missed nearby POIs just
  /// outside the rectangle (e.g. south of 33.40° while the map is Islamabad).
  static const int _searchRadiusM = 85000;

  final MapController _mapController = MapController();

  List<Map<String, dynamic>> vets = [];
  Map<String, dynamic>? selectedVet;
  bool isLoadingVets = true;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// flutter_map can cull markers when [MapCamera.pixelBounds] is not ready yet
  /// (often seen on Android). A tiny camera nudge after data loads forces a
  /// correct repaint without visible movement.
  void _nudgeMapAfterMarkersLoaded() {
    if (vets.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || vets.isEmpty) return;
      try {
        final cam = _mapController.camera;
        final center = cam.center;
        final zoom = cam.zoom;
        if (_mapController.move(center, zoom + 0.001)) {
          _mapController.move(center, zoom);
        }
      } catch (_) {
        // Map not linked to controller yet; panning the map will still refresh.
      }
    });
  }

  Future<void> fetchNearbyVets() async {
    final lat = _mapCenter.latitude;
    final lon = _mapCenter.longitude;
    final r = _searchRadiusM;
    final query = '''
[out:json][timeout:60];
(
  node["amenity"="veterinary"](around:$r,$lat,$lon);
  way["amenity"="veterinary"](around:$r,$lat,$lon);
  relation["amenity"="veterinary"](around:$r,$lat,$lon);
  node["healthcare"="veterinary"](around:$r,$lat,$lon);
  way["healthcare"="veterinary"](around:$r,$lat,$lon);
  relation["healthcare"="veterinary"](around:$r,$lat,$lon);
  node["name"~"animal|vet|veterinary|pet", i](around:$r,$lat,$lon);
  way["name"~"animal|vet|veterinary|pet", i](around:$r,$lat,$lon);
  relation["name"~"animal|vet|veterinary|pet", i](around:$r,$lat,$lon);
);
out center;
''';

    const endpoints = [
      'https://overpass.kumi.systems/api/interpreter',
      'https://overpass.openstreetmap.fr/api/interpreter',
      'https://overpass-api.de/api/interpreter',
    ];

    final body = 'data=${Uri.encodeQueryComponent(query)}';
    const headers = {
      'User-Agent': 'Pawsome/1.0 (Flutter student app; contact via store listing)',
      'Accept': '*/*',
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    };

    for (final endpoint in endpoints) {
      try {
        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: headers,
              body: body,
            )
            .timeout(const Duration(seconds: 60));

        if (response.statusCode != 200) continue;

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawElements = data['elements'];
        if (rawElements is! List) continue;

        final parsed = <Map<String, dynamic>>[];
        for (final item in rawElements) {
          if (item is! Map) continue;
          final m = Map<String, dynamic>.from(item);
          final tagsRaw = m['tags'];
          final tags = tagsRaw is Map
              ? Map<String, dynamic>.from(tagsRaw)
              : <String, dynamic>{};

          final latRaw = m['lat'] ?? (m['center'] is Map
              ? (m['center'] as Map)['lat']
              : null);
          final lonRaw = m['lon'] ?? (m['center'] is Map
              ? (m['center'] as Map)['lon']
              : null);
          final lat = latRaw is num
              ? latRaw.toDouble()
              : double.tryParse(latRaw?.toString() ?? '');
          final lon = lonRaw is num
              ? lonRaw.toDouble()
              : double.tryParse(lonRaw?.toString() ?? '');
          if (lat == null || lon == null) continue;

          parsed.add({
            'name': tags['name'] as String? ?? 'Unnamed Vet Clinic',
            'phone': tags['phone'] as String? ??
                tags['contact:phone'] as String? ??
                'No phone available',
            'location': LatLng(lat, lon),
          });
        }

        if (!mounted) return;
        setState(() {
          vets = parsed;
          isLoadingVets = false;
        });
        _nudgeMapAfterMarkersLoaded();
        return;
      } catch (_) {
        continue;
      }
    }

    if (!mounted) return;
    setState(() {
      isLoadingVets = false;
    });
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
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _mapCenter,
                        initialZoom: 12.5,
                        onMapReady: fetchNearbyVets,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.pawsome',
                        ),
                        MarkerLayer(
                          key: ValueKey(vets.length),
                          markers: vets.map((vet) {
                            return Marker(
                              point: vet['location'],
                              width: 80,
                              height: 80,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedVet = vet;
                                  });
                                },
                                child: const Icon(
                                  Icons.pets,
                                  color: Colors.red,
                                  size: 38,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  if (selectedVet != null)
                    Positioned(
                      top: 120,
                      left: 40,
                      child: _buildDoctorCard(
                        name: selectedVet!['name'],
                        specialty: "Veterinary Clinic",
                        phone: selectedVet!['phone'],
                        color: AppColors.primary,
                      ),
                    ),

                  Positioned(
                    bottom: 120,
                    left: 20,
                    child: _buildDoctorCard(
                      name: "Dr.Ahmed Ali",
                      specialty: "Internal Medicine",
                      phone: "+92 9232936633",
                      color: AppColors.secondary,
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
        color: color.withValues(alpha: 0.9),
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
      constraints: const BoxConstraints(maxHeight: 260),
      padding: const EdgeInsets.all(15),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: isLoadingVets
          ? const Center(child: CircularProgressIndicator())
          : vets.isEmpty
          ? const Center(
              child: Text(
                "No vets found nearby",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              itemCount: vets.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final vet = vets[index];

                return _buildClinicTile(
                  vet['name'],
                  "Veterinary Clinic",
                  vet['phone'],
                  4.0,
                );
              },
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
              Text(
                time,
                style: const TextStyle(color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Column(children: const [HoverCallButton()]),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 4,
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

class HoverCallButton extends StatefulWidget {
  const HoverCallButton({super.key});

  @override
  State<HoverCallButton> createState() => _HoverCallButtonState();
}

class _HoverCallButtonState extends State<HoverCallButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isHovered ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isHovered ? 1.0 : 0.7,
              child: Icon(
                Icons.phone,
                color: isHovered ? Colors.red : Colors.blue,
              ),
            ),
            const SizedBox(width: 5),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isHovered ? Colors.red : Colors.blue,
                fontWeight: FontWeight.w500,
              ),
              child: const Text("Call"),
            ),
          ],
        ),
      ),
    );
  }
}
