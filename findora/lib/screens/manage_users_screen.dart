import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/admin_controller.dart';
import '../models/auth_user.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  late final AdminController _ctrl;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<AdminController>();
    _ctrl.fetchUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleBan(AuthUser user) async {
    final ok = user.banned
        ? await _ctrl.unbanUser(user.id)
        : await _ctrl.banUser(user.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? (user.banned ? 'User unbanned' : 'User banned')
            : 'Action failed'),
      ),
    );
  }

  Future<void> _deleteUser(AuthUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete ${user.fullName}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final ok = await _ctrl.deleteUser(user.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'User deleted' : 'Failed to delete user')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xff17324D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manage Users',
          style: TextStyle(color: Color(0xff17324D), fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name or email…',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (q) => _ctrl.fetchUsers(q: q.trim()),
              onChanged: (q) {
                if (q.isEmpty) _ctrl.fetchUsers();
              },
            ),
          ),
          Expanded(
            child: Obx(() {
              if (_ctrl.usersLoading.value && _ctrl.users.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_ctrl.users.isEmpty) {
                return const Center(
                  child: Text('No users found', style: TextStyle(color: Colors.black54)),
                );
              }
              return RefreshIndicator(
                onRefresh: () => _ctrl.fetchUsers(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: _ctrl.users.length,
                  itemBuilder: (context, index) {
                    final user = _ctrl.users[index];
                    return _userCard(user);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _userCard(AuthUser user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.white, Color(0xffF4FAFF)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(.08), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: user.banned ? const Color(0xffFFEBEB) : const Color(0xffDCEFFF),
            child: Icon(
              Icons.person,
              color: user.banned ? Colors.red : const Color(0xff0A5EB0),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xff17324D)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.role == 'admin')
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xffEAF5FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Admin', style: TextStyle(fontSize: 11, color: Color(0xff0A5EB0), fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(user.email, style: const TextStyle(color: Colors.black54, fontSize: 13), overflow: TextOverflow.ellipsis),
                if (user.banned)
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Text('Banned', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'ban') _toggleBan(user);
              if (value == 'delete') _deleteUser(user);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'ban',
                child: Text(user.banned ? 'Unban User' : 'Ban User'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete User', style: TextStyle(color: Colors.red)),
              ),
            ],
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: user.banned ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                elevation: 0,
              ),
              onPressed: () => _toggleBan(user),
              child: Text(user.banned ? 'Unban' : 'Ban', style: const TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
