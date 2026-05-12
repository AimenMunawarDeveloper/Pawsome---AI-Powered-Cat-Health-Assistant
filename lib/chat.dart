import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import "home.dart";
import "profile.dart";
import "logs.dart";
import "health.dart";
import "vet.dart";
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'login.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile_data_service.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> with SingleTickerProviderStateMixin {
  int _currentIndex = 3;
  final ProfileDataService _profileDataService = ProfileDataService();

  late String apiKey;

  bool _isBotTyping = false;
  final TextEditingController _messageController = TextEditingController();
  List<ChatMessage> _messages = [];
  ChatFlowStep _flowStep = ChatFlowStep.none;
  final Map<String, String> _flowAnswers = <String, String>{};

  late AnimationController _controller;
  late Animation<Offset> _animation;

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

    apiKey = (dotenv.env['GROQ_API_KEY'] ?? '').trim();

    debugPrint("GROQ KEY LOADED: ${apiKey.isNotEmpty}");
    debugPrint("KEY LENGTH: ${apiKey.length}");

    _messages.add(
      ChatMessage(
        text:
            "Hello! I am Dr. Meow.\n"
            "Feel free to ask me anything about your cat health.\n"
            "You can also choose: Register Cat, Add Care Log, Consult, Tips, or Stress Analysis.",
        isUser: false,
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _animation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: const Offset(1, 0),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSendPressed() async {
    final userMessage = _messageController.text.trim();

    if (userMessage.isEmpty || _isBotTyping) return;

    setState(() {
      _messages.add(ChatMessage(text: userMessage, isUser: true));
      _messageController.clear();
    });

    await _handleUserInput(userMessage);
  }

  Future<void> _handleUserInput(String userMessage) async {
    if (_flowStep != ChatFlowStep.none) {
      await _continueFlow(userMessage);
      return;
    }

    final normalized = userMessage.toLowerCase();
    if (normalized.contains('register cat')) {
      _startRegisterCatFlow();
      return;
    }
    if (normalized.contains('add log') || normalized.contains('care log')) {
      _startCareLogFlow();
      return;
    }
    if (normalized.contains('consult')) {
      _startConsultFlow();
      return;
    }
    if (normalized.contains('tips')) {
      _showTips();
      return;
    }
    if (normalized.contains('stress')) {
      _startStressAnalysisFlow();
      return;
    }

    await _sendToAi();
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: false));
    });
  }

  void _startRegisterCatFlow() {
    _flowAnswers.clear();
    _flowStep = ChatFlowStep.registerName;
    _addBotMessage("Let's register your cat. What is your cat's name?");
  }

  void _startCareLogFlow() {
    _flowAnswers.clear();
    _flowStep = ChatFlowStep.careCondition;
    _addBotMessage("Let's add today's care log. How is their condition today?");
  }

  void _startConsultFlow() {
    _flowAnswers.clear();
    _flowStep = ChatFlowStep.consultPrompt;
    _addBotMessage(
      "Sure. Tell me your main concern about your cat, and I will give a quick consult.",
    );
  }

  void _showTips() {
    _addBotMessage(
      "Quick cat care tips:\n"
      "1) Keep fresh water available all day.\n"
      "2) Track appetite, poop, and weight daily.\n"
      "3) Give 15-20 minutes of active play.\n"
      "4) Clean litter box daily.\n"
      "5) See a vet if symptoms last more than 24 hours.",
    );
  }

  void _startStressAnalysisFlow() {
    _flowAnswers.clear();
    _flowStep = ChatFlowStep.stressActivity;
    _addBotMessage(
      "Let's do a stress analysis. How active is your cat today? (high/normal/low)",
    );
  }

  Future<void> _continueFlow(String userMessage) async {
    switch (_flowStep) {
      case ChatFlowStep.registerName:
        _flowAnswers['name'] = userMessage;
        _flowStep = ChatFlowStep.registerBreed;
        _addBotMessage("Great. What is their breed?");
        break;
      case ChatFlowStep.registerBreed:
        _flowAnswers['breed'] = userMessage;
        _flowStep = ChatFlowStep.registerAge;
        _addBotMessage("How old is your cat?");
        break;
      case ChatFlowStep.registerAge:
        _flowAnswers['age'] = userMessage;
        _flowStep = ChatFlowStep.registerGender;
        _addBotMessage("What is their gender?");
        break;
      case ChatFlowStep.registerGender:
        _flowAnswers['gender'] = userMessage;
        _flowStep = ChatFlowStep.registerWeight;
        _addBotMessage("What is their current weight in kg?");
        break;
      case ChatFlowStep.registerWeight:
        _flowAnswers['weight'] = userMessage;
        await _saveCatRegistration();
        break;
      case ChatFlowStep.careCondition:
        _flowAnswers['condition'] = userMessage;
        _flowStep = ChatFlowStep.careAppetite;
        _addBotMessage("How about appetite?");
        break;
      case ChatFlowStep.careAppetite:
        _flowAnswers['appetite'] = userMessage;
        _flowStep = ChatFlowStep.careDefecation;
        _addBotMessage("How about defecation?");
        break;
      case ChatFlowStep.careDefecation:
        _flowAnswers['defecation'] = userMessage;
        _flowStep = ChatFlowStep.careWeight;
        _addBotMessage("What is their weight today in kg?");
        break;
      case ChatFlowStep.careWeight:
        _flowAnswers['weightKg'] = userMessage;
        await _saveCareLog();
        break;
      case ChatFlowStep.consultPrompt:
        await _handleConsult(userMessage);
        break;
      case ChatFlowStep.stressActivity:
        _flowAnswers['stressActivity'] = userMessage;
        _flowStep = ChatFlowStep.stressHiding;
        _addBotMessage("Are they hiding more than usual? (yes/no)");
        break;
      case ChatFlowStep.stressHiding:
        _flowAnswers['stressHiding'] = userMessage;
        _flowStep = ChatFlowStep.stressVocal;
        _addBotMessage("How is vocalization today? (normal/more/less)");
        break;
      case ChatFlowStep.stressVocal:
        _flowAnswers['stressVocal'] = userMessage;
        _flowStep = ChatFlowStep.stressAggression;
        _addBotMessage("Any aggression or irritability? (none/mild/high)");
        break;
      case ChatFlowStep.stressAggression:
        _flowAnswers['stressAggression'] = userMessage;
        _flowStep = ChatFlowStep.stressAppetite;
        _addBotMessage("How is appetite today? (good/normal/reduced/none)");
        break;
      case ChatFlowStep.stressAppetite:
        _flowAnswers['stressAppetite'] = userMessage;
        await _saveStressAnalysis();
        break;
      case ChatFlowStep.none:
        break;
    }
  }

  Future<void> _handleConsult(String concern) async {
    setState(() {
      _isBotTyping = true;
    });
    if (apiKey.isEmpty) {
      _addBotMessage(
        "Chat API key is missing. Add GROQ_API_KEY to your .env file and rebuild the app.",
      );
      setState(() => _isBotTyping = false);
      _flowAnswers.clear();
      _flowStep = ChatFlowStep.none;
      return;
    }
    try {
      final response = await http
          .post(
            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
              'User-Agent': 'Pawsome/1.0 (Flutter)',
            },
            body: jsonEncode({
              "model": "llama-3.3-70b-versatile",
              "messages": [
                {
                  "role": "system",
                  "content":
                      "You are Dr. Meow. Give short, practical cat consult advice based on symptoms. If emergency signs exist, advise immediate vet visit."
                },
                {"role": "user", "content": concern}
              ],
              "temperature": 0.5,
              "max_tokens": 250
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        final err = _groqErrorMessage(response.body);
        _addBotMessage(err ?? "I couldn't consult right now. Please try again.");
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final reply =
          data['choices']?[0]?['message']?['content'] as String? ??
          "I couldn't consult right now.";
      _addBotMessage(reply);
    } catch (_) {
      _addBotMessage("I couldn't consult right now. Please try again.");
    } finally {
      setState(() {
        _isBotTyping = false;
      });
      _flowAnswers.clear();
      _flowStep = ChatFlowStep.none;
    }
  }

  int _scoreFromAnswer(String answer, Map<String, int> map, int fallback) {
    final value = map[answer.trim().toLowerCase()];
    return value ?? fallback;
  }

  Future<void> _saveStressAnalysis() async {
    final activity = _scoreFromAnswer(
      _flowAnswers['stressActivity'] ?? '',
      {'high': 0, 'normal': 1, 'low': 3},
      1,
    );
    final hiding = _scoreFromAnswer(
      _flowAnswers['stressHiding'] ?? '',
      {'no': 0, 'yes': 3},
      1,
    );
    final vocal = _scoreFromAnswer(
      _flowAnswers['stressVocal'] ?? '',
      {'normal': 0, 'more': 2, 'less': 1},
      1,
    );
    final aggression = _scoreFromAnswer(
      _flowAnswers['stressAggression'] ?? '',
      {'none': 0, 'mild': 2, 'high': 4},
      1,
    );
    final appetite = _scoreFromAnswer(
      _flowAnswers['stressAppetite'] ?? '',
      {'good': 0, 'normal': 0, 'reduced': 2, 'none': 4},
      1,
    );

    final stressScore = (activity + hiding + vocal + aggression + appetite)
        .clamp(0, 10);
    final level = stressScore <= 3
        ? "Low"
        : stressScore <= 6
            ? "Moderate"
            : "High";

    try {
      await _profileDataService.addStressLog(
        stressScore: stressScore,
        level: level,
        answers: <String, String>{
          'activity': _flowAnswers['stressActivity'] ?? '',
          'hiding': _flowAnswers['stressHiding'] ?? '',
          'vocalization': _flowAnswers['stressVocal'] ?? '',
          'aggression': _flowAnswers['stressAggression'] ?? '',
          'appetite': _flowAnswers['stressAppetite'] ?? '',
        },
      );
      _addBotMessage(
        "Stress analysis complete.\n"
        "Stress Score: $stressScore/10 ($level)\n"
        "Recorded in logs for today.\n"
        "If stress stays moderate/high for more than 1-2 days, please consult a vet.",
      );
    } catch (_) {
      _addBotMessage(
        "Stress analysis complete.\n"
        "Stress Score: $stressScore/10 ($level)\n"
        "I couldn't save it to logs right now. Please try again.",
      );
    } finally {
      _flowAnswers.clear();
      _flowStep = ChatFlowStep.none;
    }
  }

  Future<void> _saveCatRegistration() async {
    try {
      await _profileDataService.updatePet(
        name: _flowAnswers['name'] ?? '',
        breed: _flowAnswers['breed'] ?? '',
        age: _flowAnswers['age'] ?? '',
        gender: _flowAnswers['gender'] ?? '',
        weight: _flowAnswers['weight'] ?? '',
      );
      _addBotMessage("Done. Your cat is registered successfully.");
    } catch (_) {
      _addBotMessage("I couldn't save your cat right now. Please try again.");
    } finally {
      _flowAnswers.clear();
      _flowStep = ChatFlowStep.none;
    }
  }

  Future<void> _saveCareLog() async {
    final parsedWeight = double.tryParse(
      (_flowAnswers['weightKg'] ?? '').replaceAll(',', '.'),
    );
    if (parsedWeight == null) {
      _addBotMessage("Please enter a valid weight in kg (example: 4.2).");
      _flowStep = ChatFlowStep.careWeight;
      return;
    }

    try {
      await _profileDataService.addCareLog(
        condition: _flowAnswers['condition'] ?? '',
        appetite: _flowAnswers['appetite'] ?? '',
        defecation: _flowAnswers['defecation'] ?? '',
        weightKg: parsedWeight,
      );
      _addBotMessage("Care log is recorded.");
    } catch (_) {
      _addBotMessage("I couldn't save the care log right now. Please try again.");
    } finally {
      _flowAnswers.clear();
      _flowStep = ChatFlowStep.none;
    }
  }

  Future<void> _sendToAi() async {
    setState(() {
      _isBotTyping = true;
    });

    if (apiKey.isEmpty) {
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                "Chat API key is missing. Add GROQ_API_KEY to your .env file and rebuild the app.",
            isUser: false,
          ),
        );
        _isBotTyping = false;
      });
      return;
    }

    try {
      List<Map<String, String>> chatHistory = [
        {
          "role": "system",
          "content": """
You are Dr. Meow, a friendly AI cat health assistant.
Only answer questions related to cats, pets, pet care, symptoms, food, grooming, and vet guidance.
Do not diagnose serious conditions with certainty.
For emergencies, tell the user to visit a vet immediately.
Keep answers short, friendly, and easy to understand.
"""
        }
      ];

      for (var msg in _messages) {
        chatHistory.add({
          "role": msg.isUser ? "user" : "assistant",
          "content": msg.text,
        });
      }

      final response = await http
          .post(
            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
              'User-Agent': 'Pawsome/1.0 (Flutter)',
            },
            body: jsonEncode({
              "model": "llama-3.3-70b-versatile",
              "messages": chatHistory,
              "temperature": 0.7,
              "max_tokens": 500
            }),
          )
          .timeout(const Duration(seconds: 60));

      debugPrint("FULL RESPONSE: ${response.body}");

      if (response.statusCode != 200) {
        final err = _groqErrorMessage(response.body) ?? "Server error. Please try again later.";
        setState(() {
          _messages.add(ChatMessage(text: err, isUser: false));
          _isBotTyping = false;
        });
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final botReply =
          data['choices']?[0]?['message']?['content'] as String? ??
          "Sorry, I couldn't understand.";

      setState(() {
        _messages.add(ChatMessage(text: botReply, isUser: false));
        _isBotTyping = false;
      });
    } catch (e) {
      debugPrint("ERROR: $e");

      setState(() {
        _messages.add(
          ChatMessage(
            text: "Server error. Please try again later.",
            isUser: false,
          ),
        );
        _isBotTyping = false;
      });
    }
  }

  /// Parses Groq JSON error body when status is not 200.
  String? _groqErrorMessage(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final err = data['error'];
      if (err is Map && err['message'] != null) {
        return err['message'].toString();
      }
    } catch (_) {}
    return null;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _messages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: SizedBox(
                                height: 150,
                                child: SlideTransition(
                                  position: _animation,
                                  child: Image.asset(
                                    "assets/images/catwalking.png",
                                    height: 150,
                                  ),
                                ),
                              ),
                            );
                          }
                          return _buildChatMessage(_messages[index]);
                        },
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: _isBotTyping ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: _buildTypingIndicator(),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _isBotTyping ? 0.5 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: _buildBottomInputSection(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          child: ClipOval(
            child: Image.asset(
              "assets/images/catdoctor.png",
              fit: BoxFit.cover,
              width: 30,
              height: 40,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDot(),
              const SizedBox(width: 4),
              _buildDot(),
              const SizedBox(width: 4),
              _buildDot(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDot() {
    return AnimatedOpacity(
      opacity: _isBotTyping ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 20,
                child: ClipOval(
                  child: Image.asset(
                    "assets/images/catdoctor.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppColors.secondarySoft
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black12),
              ),
              child: Text(
                message.text,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInputSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text("Register Cat"),
                onPressed: _isBotTyping
                    ? null
                    : () {
                        setState(() {
                          _messages.add(
                            ChatMessage(text: "Register Cat", isUser: true),
                          );
                        });
                        _startRegisterCatFlow();
                      },
              ),
              ActionChip(
                label: const Text("Add Care Log"),
                onPressed: _isBotTyping
                    ? null
                    : () {
                        setState(() {
                          _messages.add(
                            ChatMessage(text: "Add Care Log", isUser: true),
                          );
                        });
                        _startCareLogFlow();
                      },
              ),
              ActionChip(
                label: const Text("Consult"),
                onPressed: _isBotTyping
                    ? null
                    : () {
                        setState(() {
                          _messages.add(
                            ChatMessage(text: "Consult", isUser: true),
                          );
                        });
                        _startConsultFlow();
                      },
              ),
              ActionChip(
                label: const Text("Tips"),
                onPressed: _isBotTyping
                    ? null
                    : () {
                        setState(() {
                          _messages.add(
                            ChatMessage(text: "Tips", isUser: true),
                          );
                        });
                        _showTips();
                      },
              ),
              ActionChip(
                label: const Text("Stress Analysis"),
                onPressed: _isBotTyping
                    ? null
                    : () {
                        setState(() {
                          _messages.add(
                            ChatMessage(text: "Stress Analysis", isUser: true),
                          );
                        });
                        _startStressAnalysisFlow();
                      },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: () {},
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: "Type a message...",
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _handleSendPressed,
              ),
            ],
          ),
        ],
      ),
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
              Image.asset("assets/images/logo.png", height: 28),
              const SizedBox(width: 8),
              Text(
                "Pawsome",
                style: GoogleFonts.leckerliOne(
                  color: AppColors.surface,
                  fontSize: 32,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.notifications_none,
                  color: AppColors.surface),
              IconButton(
                onPressed: _signOut,
                icon: const Icon(Icons.logout,
                    color: AppColors.surface),
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
              _drawerItem(Icons.home, "Home",
                  () => Navigator.pushReplacement(
                      context, _createRoute(const Home()))),
              _drawerItem(Icons.list_alt, "Logs",
                  () => Navigator.pushReplacement(
                      context, _createRoute(const Logs()))),
              _drawerItem(Icons.favorite, "Health",
                  () => Navigator.pushReplacement(
                      context, _createRoute(const Health()))),
              _drawerItem(Icons.auto_awesome, "AI Chat",
                  () => Navigator.pushReplacement(
                      context, _createRoute(const Chat()))),
              _drawerItem(Icons.location_on, "Vet Locator",
                  () => Navigator.pushReplacement(
                      context, _createRoute(const Vet()))),
              _drawerItem(Icons.person, "Profile",
                  () => Navigator.pushReplacement(
                      context, _createRoute(const Profile()))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(
      IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.black87),
        title: Text(
          title,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w500),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 3,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.primary,
      selectedItemColor: AppColors.navSelected,
      unselectedItemColor: AppColors.surface,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacement(
              context, _createRoute(const Home()));
        }
        if (index == 1) {
          Navigator.pushReplacement(
              context, _createRoute(const Logs()));
        }
        if (index == 2) {
          Navigator.pushReplacement(
              context, _createRoute(const Health()));
        }
        if (index == 3) {
          Navigator.pushReplacement(
              context, _createRoute(const Chat()));
        }
        if (index == 4) {
          Navigator.pushReplacement(
              context, _createRoute(const Vet()));
        }
        if (index == 5) {
          Navigator.pushReplacement(
              context, _createRoute(const Profile()));
        }
      },
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(
            icon: Icon(Icons.list), label: "Logs"),
        BottomNavigationBarItem(
            icon: Icon(Icons.favorite), label: "Health"),
        BottomNavigationBarItem(
            icon: Icon(Icons.chat), label: "Chat"),
        BottomNavigationBarItem(
            icon: Icon(Icons.location_city), label: "Vet"),
        BottomNavigationBarItem(
            icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({
    required this.text,
    required this.isUser,
  });
}

enum ChatFlowStep {
  none,
  registerName,
  registerBreed,
  registerAge,
  registerGender,
  registerWeight,
  careCondition,
  careAppetite,
  careDefecation,
  careWeight,
  consultPrompt,
  stressActivity,
  stressHiding,
  stressVocal,
  stressAggression,
  stressAppetite,
}