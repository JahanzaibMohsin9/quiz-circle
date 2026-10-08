import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/quiz/domain/entities/quiz_permissions.dart';
import '../../../features/admin/domain/entities/admin_user.dart';
import '../common/custom_button.dart';

class PermissionManagerWidget extends ConsumerStatefulWidget {
  final QuizPermissions permissions;
  final Function(QuizPermissions) onPermissionsChanged;
  final List<AdminUser> availableUsers;

  const PermissionManagerWidget({
    super.key,
    required this.permissions,
    required this.onPermissionsChanged,
    required this.availableUsers,
  });

  @override
  ConsumerState<PermissionManagerWidget> createState() =>
      _PermissionManagerWidgetState();
}

class _PermissionManagerWidgetState
    extends ConsumerState<PermissionManagerWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Set<String> _selectedUsers = {};
  DateTime? _startDate;
  DateTime? _endDate;
  String _accessLevel = 'public'; // Default to public

  @override
  void initState() {
    super.initState();
    _selectedUsers = Set.from(widget.permissions.allowedUserIds);
    _startDate = widget.permissions.availableFrom;
    _endDate = widget.permissions.availableUntil;

    // Determine initial access level based on current permissions
    _accessLevel = _determineAccessLevel(widget.permissions);

    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant,
            tabs: const [
              Tab(text: 'Access'),
              Tab(text: 'Users'),
              Tab(text: 'Schedule'),
            ],
          ),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAccessTab(),
                _buildUserSelectionTab(),
                _buildScheduleTab(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomButton(
              text: 'Apply Changes',
              onPressed: _applyChanges,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Access Level',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          RadioGroup<String>(
            groupValue: _accessLevel,
            onChanged: (value) => setState(() => _accessLevel = value!),
            child: const Column(
              children: [
                RadioListTile<String>(
                  title: Text('Public Quiz'),
                  subtitle: Text('Available to all students'),
                  value: 'public',
                ),
                RadioListTile<String>(
                  title: Text('Private Quiz'),
                  subtitle: Text('Only selected users can access'),
                  value: 'private',
                ),
                RadioListTile<String>(
                  title: Text('Role-based'),
                  subtitle: Text('Based on user roles'),
                  value: 'role-based',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSelectionTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search Users',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              // Implement search logic if needed
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: widget.availableUsers.length,
              itemBuilder: (context, index) {
                final user = widget.availableUsers[index];
                final isSelected = _selectedUsers.contains(user.id);
                return CheckboxListTile(
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedUsers.add(user.id);
                      } else {
                        _selectedUsers.remove(user.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ListTile(
            title: const Text('Available From'),
            subtitle: Text(_startDate?.toString() ?? 'Not set'),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickStartDate,
          ),
          ListTile(
            title: const Text('Available Until'),
            subtitle: Text(_endDate?.toString() ?? 'Not set'),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickEndDate,
          ),
        ],
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  void _applyChanges() {
    final updatedPermissions = _buildPermissionsFromSelection();
    widget.onPermissionsChanged(updatedPermissions);
  }

  QuizPermissions _buildPermissionsFromSelection() {
    switch (_accessLevel) {
      case 'public':
        return widget.permissions.copyWith(
          allowedUserIds: {},
          allowedRoles: {'student'},
        );
      case 'private':
        return widget.permissions.copyWith(
          allowedUserIds: _selectedUsers,
          allowedRoles: {},
        );
      case 'role-based':
        return widget.permissions.copyWith(
          allowedUserIds: _selectedUsers,
          allowedRoles: {'student', 'admin', 'teacher'},
        );
      default:
        return widget.permissions.copyWith(
          allowedUserIds: _selectedUsers,
          allowedRoles: {'student'},
          availableFrom: _startDate,
          availableUntil: _endDate,
        );
    }
  }

  String _determineAccessLevel(QuizPermissions permissions) {
    // Check if it's scheduled first
    if (permissions.availableFrom != null ||
        permissions.availableUntil != null) {
      return 'scheduled';
    }

    // Check if it's private (specific users)
    if (permissions.allowedUserIds.isNotEmpty) {
      return 'private';
    }

    // Check if it's public (all students)
    if (permissions.allowedRoles.contains('student') &&
        permissions.allowedRoles.length == 1) {
      return 'public';
    }

    // Otherwise it's role-based
    return 'role-based';
  }
}
