import 'package:flutter/material.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final List<Map<String, dynamic>> users = [
    {"name": "Ali Raza", "email": "ali@email.com", "blocked": false},
    {"name": "Sara Khan", "email": "sara@email.com", "blocked": true},
    {"name": "Hassan Ahmed", "email": "hassan@email.com", "blocked": false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xff17324D),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Manage Users",
          style: TextStyle(
            color: Color(0xff17324D),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xffF4FAFF)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Color(0xffDCEFFF),
                  child: Icon(Icons.person, color: Color(0xff0A5EB0)),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user["name"],
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xff17324D),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        user["email"],
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: user["blocked"]
                        ? Colors.green
                        : Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      user["blocked"] = !user["blocked"];
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          user["blocked"] ? "User Blocked" : "User Unblocked",
                        ),
                      ),
                    );
                  },
                  child: Text(user["blocked"] ? "Unblock" : "Block"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
