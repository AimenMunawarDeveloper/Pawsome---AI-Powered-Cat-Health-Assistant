import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_firestore.dart';

class ProfileDataService {
  ProfileDataService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? appFirestore,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const List<Map<String, dynamic>> _defaultDailyTasks = [
    {'title': 'Brush teeth', 'done': false},
    {'title': 'Eaten food', 'done': false},
    {'title': 'Drank water', 'done': false},
    {'title': 'Played', 'done': false},
  ];

  static const List<Map<String, dynamic>> _defaultExtraActivities = [
    {'title': 'Go for walk', 'done': false},
    {'title': 'Eaten treats', 'done': false},
    {'title': 'Bath', 'done': false},
    {'title': 'Vaccination', 'done': false},
  ];

  static const List<Map<String, dynamic>> _defaultRecommendations = [
    {
      'title': 'Offer fresh water in a clean bowl every day.',
      'image': 'assets/images/tip1.png',
      'order': 1,
    },
    {
      'title': 'Set aside playtime with a toy to keep your cat active.',
      'image': 'assets/images/tip2.png',
      'order': 2,
    },
    {
      'title': 'Keep the litter box clean and in a quiet place.',
      'image': 'assets/images/tip2.png',
      'order': 3,
    },
  ];

  DocumentReference<Map<String, dynamic>> get _profileDoc {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed in user found.');
    }
    return _firestore.collection('profiles').doc(user.uid);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> profileStream() {
    return _profileDoc.snapshots();
  }

  Future<Map<String, dynamic>> getProfileData() async {
    final snapshot = await _profileDoc.get();
    return snapshot.data() ?? <String, dynamic>{};
  }

  Future<void> createProfileIfMissing({
    required String name,
    required String email,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed in user found.');
    }

    final snapshot = await _profileDoc.get();
    if (snapshot.exists) return;

    await _profileDoc.set({
      'guardian': {
        'name': name,
        'email': email,
        'contactNo': '',
        'address': '',
        'emergencyNo': '',
      },
      'pet': {'name': '', 'breed': '', 'age': '', 'gender': '', 'weight': ''},
      'health': {
        'vetName': '',
        'vetPhone': '',
        'lastVisit': '',
        'lastWeight': '',
        'vaccinations': <Map<String, String>>[],
        'allergies': <String>[],
      },
      'home': {
        'dailyTasks': _defaultDailyTasks,
        'extraActivities': _defaultExtraActivities,
        'recommendations': _defaultRecommendations,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> ensureHomeData() async {
    final snapshot = await _profileDoc.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final home = Map<String, dynamic>.from(
      data['home'] as Map<String, dynamic>? ?? {},
    );

    final updates = <String, dynamic>{};
    if (!home.containsKey('dailyTasks')) {
      updates['home.dailyTasks'] = _defaultDailyTasks;
    }
    if (!home.containsKey('extraActivities')) {
      updates['home.extraActivities'] = _defaultExtraActivities;
    }
    if (!home.containsKey('recommendations')) {
      updates['home.recommendations'] = _defaultRecommendations;
    }

    if (updates.isEmpty) return;

    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _profileDoc.set(updates, SetOptions(merge: true));
  }

  Future<void> updateGuardian({
    required String name,
    required String email,
    required String contactNo,
    required String address,
    required String emergencyNo,
  }) async {
    await _profileDoc.set({
      'guardian': {
        'name': name,
        'email': email,
        'contactNo': contactNo,
        'address': address,
        'emergencyNo': emergencyNo,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final user = _auth.currentUser;
    if (user != null && user.displayName != name) {
      await user.updateDisplayName(name);
    }
  }

  Future<void> updatePet({
    required String name,
    required String breed,
    required String age,
    required String gender,
    required String weight,
  }) async {
    await _profileDoc.set({
      'pet': {
        'name': name,
        'breed': breed,
        'age': age,
        'gender': gender,
        'weight': weight,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateHealthSummary({
    required String vetName,
    required String vetPhone,
    required String lastVisit,
    required String lastWeight,
  }) async {
    await _profileDoc.set({
      'health': {
        'vetName': vetName,
        'vetPhone': vetPhone,
        'lastVisit': lastVisit,
        'lastWeight': lastWeight,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addVaccination({
    required String name,
    required String date,
  }) async {
    final snapshot = await _profileDoc.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final health = Map<String, dynamic>.from(
      data['health'] as Map<String, dynamic>? ?? {},
    );
    final vaccinations = List<Map<String, String>>.from(
      ((health['vaccinations'] as List<dynamic>? ?? const <dynamic>[]).map(
        (entry) => Map<String, String>.from(entry as Map),
      )),
    );

    vaccinations.add({'name': name, 'date': date});

    await _profileDoc.set({
      'health': {...health, 'vaccinations': vaccinations},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeVaccinationAt(int index) async {
    final snapshot = await _profileDoc.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final health = Map<String, dynamic>.from(
      data['health'] as Map<String, dynamic>? ?? {},
    );
    final vaccinations = List<Map<String, String>>.from(
      ((health['vaccinations'] as List<dynamic>? ?? const <dynamic>[]).map(
        (entry) => Map<String, String>.from(entry as Map),
      )),
    );

    if (index < 0 || index >= vaccinations.length) return;
    vaccinations.removeAt(index);

    await _profileDoc.set({
      'health': {...health, 'vaccinations': vaccinations},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addAllergy(String allergy) async {
    final snapshot = await _profileDoc.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final health = Map<String, dynamic>.from(
      data['health'] as Map<String, dynamic>? ?? {},
    );
    final allergies = List<String>.from(
      health['allergies'] as List<dynamic>? ?? const <dynamic>[],
    );

    if (!allergies.contains(allergy)) {
      allergies.add(allergy);
    }

    await _profileDoc.set({
      'health': {...health, 'allergies': allergies},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeAllergyAt(int index) async {
    final snapshot = await _profileDoc.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final health = Map<String, dynamic>.from(
      data['health'] as Map<String, dynamic>? ?? {},
    );
    final allergies = List<String>.from(
      health['allergies'] as List<dynamic>? ?? const <dynamic>[],
    );

    if (index < 0 || index >= allergies.length) return;
    allergies.removeAt(index);

    await _profileDoc.set({
      'health': {...health, 'allergies': allergies},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addHomeTask({
    required String section,
    required String title,
  }) async {
    final snapshot = await _profileDoc.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final home = Map<String, dynamic>.from(
      data['home'] as Map<String, dynamic>? ?? {},
    );
    final tasks = List<Map<String, dynamic>>.from(
      ((home[section] as List<dynamic>? ?? const <dynamic>[]).map(
        (entry) => Map<String, dynamic>.from(entry as Map),
      )),
    );

    tasks.add({'title': title, 'done': false});

    await _profileDoc.set({
      'home': {...home, section: tasks},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateHomeTaskStatus({
    required String section,
    required int index,
    required bool done,
  }) async {
    final snapshot = await _profileDoc.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final home = Map<String, dynamic>.from(
      data['home'] as Map<String, dynamic>? ?? {},
    );
    final tasks = List<Map<String, dynamic>>.from(
      ((home[section] as List<dynamic>? ?? const <dynamic>[]).map(
        (entry) => Map<String, dynamic>.from(entry as Map),
      )),
    );

    if (index < 0 || index >= tasks.length) return;

    tasks[index] = {...tasks[index], 'done': done};

    await _profileDoc.set({
      'home': {...home, section: tasks},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  List<Map<String, dynamic>> _normalizedRecommendations(
    Map<String, dynamic> profileData,
  ) {
    final home = Map<String, dynamic>.from(
      profileData['home'] as Map<String, dynamic>? ?? {},
    );
    final rawRecommendations =
        home['recommendations'] as List<dynamic>? ?? const <dynamic>[];

    final recommendations = rawRecommendations.whereType<Map>().map((entry) {
      final data = Map<String, dynamic>.from(entry);
      return {
        'title': data['title']?.toString() ?? 'Helpful tip',
        'image': data['image']?.toString() ?? 'assets/images/tip1.png',
        'order': data['order'] is num ? (data['order'] as num).toInt() : 999,
      };
    }).toList();

    recommendations.sort(
      (a, b) => (a['order'] as int).compareTo(b['order'] as int),
    );

    return recommendations;
  }

  Future<List<Map<String, dynamic>>> getRecommendations() async {
    try {
      final profileData = await getProfileData();
      return _normalizedRecommendations(profileData);
    } on FirebaseException {
      return const <Map<String, dynamic>>[];
    } on TypeError {
      return const <Map<String, dynamic>>[];
    }
  }

  Stream<List<Map<String, dynamic>>> recommendationsStream() {
    return profileStream().map((snapshot) {
      final profileData = snapshot.data() ?? <String, dynamic>{};
      return _normalizedRecommendations(profileData);
    });
  }

  Future<void> seedDefaultRecommendationsForCurrentUser() async {
    await _profileDoc.set({
      'home': {'recommendations': _defaultRecommendations},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  int calculateCareHealthScore({
    required String condition,
    required String appetite,
    required String defecation,
    required double weightKg,
  }) {
    const conditionScores = <String, int>{
      'excellent': 10,
      'good': 8,
      'okay': 6,
      'poor': 3,
    };
    const appetiteScores = <String, int>{
      'great': 10,
      'normal': 8,
      'reduced': 5,
      'none': 2,
    };
    const defecationScores = <String, int>{
      'normal': 10,
      'soft': 7,
      'diarrhea': 3,
      'constipation': 4,
    };

    final conditionScore =
        conditionScores[condition.trim().toLowerCase()] ?? 6;
    final appetiteScore = appetiteScores[appetite.trim().toLowerCase()] ?? 6;
    final defecationScore =
        defecationScores[defecation.trim().toLowerCase()] ?? 6;

    int weightScore = 8;
    if (weightKg <= 0) {
      weightScore = 2;
    } else if (weightKg < 2.0 || weightKg > 8.0) {
      weightScore = 5;
    }

    final average =
        (conditionScore + appetiteScore + defecationScore + weightScore) / 4;
    return average.round().clamp(1, 10);
  }

  Future<void> addCareLog({
    required String condition,
    required String appetite,
    required String defecation,
    required double weightKg,
    DateTime? date,
  }) async {
    final now = DateTime.now();
    final targetDate = date ?? now;
    final dateKey = _dateKey(targetDate);
    final score = calculateCareHealthScore(
      condition: condition,
      appetite: appetite,
      defecation: defecation,
      weightKg: weightKg,
    );

    await _profileDoc.set({
      'logs': {
        'careLogs': {
          dateKey: {
            'condition': condition,
            'appetite': appetite,
            'defecation': defecation,
            'weightKg': weightKg,
            'healthScore': score,
            'recordedAt': FieldValue.serverTimestamp(),
          },
        },
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addStressLog({
    required int stressScore,
    required String level,
    required Map<String, String> answers,
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final dateKey = _dateKey(targetDate);
    final clampedScore = stressScore.clamp(0, 10);

    await _profileDoc.set({
      'logs': {
        'stressLogs': {
          dateKey: {
            'stressScore': clampedScore,
            'level': level,
            'answers': answers,
            'recordedAt': FieldValue.serverTimestamp(),
          },
        },
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Map<String, dynamic>? careLogForDate(
    Map<String, dynamic> profileData,
    DateTime date,
  ) {
    final logs = Map<String, dynamic>.from(
      profileData['logs'] as Map<String, dynamic>? ?? {},
    );
    final careLogs = Map<String, dynamic>.from(
      logs['careLogs'] as Map<String, dynamic>? ?? {},
    );
    final dateKey = _dateKey(date);
    final entry = careLogs[dateKey];
    if (entry is Map) {
      return Map<String, dynamic>.from(entry);
    }
    return null;
  }

  Map<String, dynamic>? stressLogForDate(
    Map<String, dynamic> profileData,
    DateTime date,
  ) {
    final logs = Map<String, dynamic>.from(
      profileData['logs'] as Map<String, dynamic>? ?? {},
    );
    final stressLogs = Map<String, dynamic>.from(
      logs['stressLogs'] as Map<String, dynamic>? ?? {},
    );
    final dateKey = _dateKey(date);
    final entry = stressLogs[dateKey];
    if (entry is Map) {
      return Map<String, dynamic>.from(entry);
    }
    return null;
  }
}
