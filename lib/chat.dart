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

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> with SingleTickerProviderStateMixin {
  int _currentIndex = 3;

  bool _isBotTyping = false;
  final TextEditingController _messageController = TextEditingController();
  List<ChatMessage> _messages = [];
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
    _messages.add(
      ChatMessage(
        text:
            "Hello! I am Dr. Meow.\n"
            "Feel free to ask me anything about your cat health.\n"
            "Send me photo and I will analyze it.",
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
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _messageController.dispose();
    super.dispose();
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
                color: message.isUser ? AppColors.secondarySoft : AppColors.surface,
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
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.camera_alt), onPressed: () {}),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(hintText: "Type a message..."),
            ),
          ),
          IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: _messageController.text, isUser: true));
      _messageController.clear();
      _isBotTyping = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isBotTyping = false;
        _messages.add(ChatMessage(text: _getBotResponse(), isUser: false));
      });
    });
  }

  String _getBotResponse() {
    List<String> responses = [
      "That's great! Keep taking care of your cat 🐱",
      "Is there anything else you'd like to know?",
      "Remember vet checkups!",
      "Ensure your cat drinks water!",
      "Play with your cat daily!",
    ];
    return responses[DateTime.now().millisecond % responses.length];
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
                Navigator.pushReplacement(
                  context,
                  _createRoute(const Home()),
                );
              }),

              _drawerItem(Icons.list_alt, "Logs", () {
                Navigator.pushReplacement(
                  context,
                  _createRoute(const Logs()),
                );
              }),

              _drawerItem(Icons.favorite, "Health", () {
                Navigator.pushReplacement(
                  context,
                  _createRoute(const Health()),
                );
              }),

              _drawerItem(Icons.auto_awesome, "AI Chat", () {
                Navigator.pushReplacement(
                  context,
                  _createRoute(const Chat()),
                );
              }),

              _drawerItem(Icons.location_on, "Vet Locator", () {
                Navigator.pushReplacement(
                  context,
                  _createRoute(const Vet()),
                );
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
            context,
            _createRoute(const Home()),
          );
        }
        if (index == 1) {
          Navigator.pushReplacement(
            context,
           _createRoute(const Logs()),
          );
        }
        if (index == 2) {
          Navigator.pushReplacement(
            context,
            _createRoute(const Health()),
          );
        }
        if (index == 3) {
          Navigator.pushReplacement(
            context,
            _createRoute(const Chat()),
          );
        }
        if (index == 4) {
          Navigator.pushReplacement(
            context,
            _createRoute(const Vet()),
          );
        }
        if (index == 5) {
          Navigator.pushReplacement(
            context,
            _createRoute(const Profile()),
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

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}
