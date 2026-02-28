import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List<bool> dailyChecked = [false, false, false, false];
  List<bool> extraChecked = [false, false, false, false];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 208, 219),
      body: SafeArea(
        child: SingleChildScrollView(
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


  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      color: const Color(0xFFB8B8E9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.menu, color: Colors.white),
           Row(
          children: [
            Image.asset(
              "assets/images/logo.png",
              height: 28, 
              width: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              "Pawsome",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
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



  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Plan Mimi’s day!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "A cute way to plan your cat’s activities and make every day more purr-fect.",
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const CircleAvatar(
            radius: 45,
            backgroundImage: AssetImage("assets/images/catprofile.png"),
          ),
        ],
      ),
    );
  }



  Widget _buildDailyTasks() {
    return _buildTaskCard(
      title: "Daily Healthy tasks",
      items: const [
        "Brush teeth",
        "Eaten food",
        "Drank Water",
        "Played",
      ],
      checkedList: dailyChecked,
      icon: Icons.check_circle_outline,
      color: const Color(0xFFB8B8E9),
    );
  }



  Widget _buildExtraActivities() {
    return _buildTaskCard(
      title: "Extra Activities",
      items: const [
        "Go for walk",
        "Eaten Treats",
        "Bath",
        "Vaccination",
      ],
      checkedList: extraChecked,
      icon: Icons.star_border,
      color: const Color(0xFFE7B2BD),
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
                const CircleAvatar(
                  backgroundColor: Colors.green,
                  radius: 14,
                  child: Icon(Icons.add, size: 16, color: Colors.white),
                )
              ],
            ),
            const SizedBox(height: 10),

            ...List.generate(items.length, (index) {
              return Column(
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          items[index],
                          style: TextStyle(
                            decoration: checkedList[index]
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                      Checkbox(
                        value: checkedList[index],
                        onChanged: (value) {
                          setState(() {
                            checkedList[index] = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }



  Widget _buildRecommendedSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recommended Tips",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildTipCard("assets/images/tip1.png", "Top 10 Ways to Wash Cat"),
              const SizedBox(width: 10),
              _buildTipCard("assets/images/tip2.png", "Why is My Cat Sad?"),
            ],
          )
        ],
      ),
    );
  }

Widget _buildTipCard(String image, String title) {
  return Expanded(
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image fills top properly
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                image,
                fit: BoxFit.cover,
              ),
            ),

            // Text section
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
    ),
  );
}


  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFFB8B8E9),
      selectedItemColor: Colors.purple,
      unselectedItemColor: Colors.white,
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