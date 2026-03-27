import 'package:flutter/material.dart';

class CrudToolbar extends StatelessWidget {
  const CrudToolbar({
    super.key,
    required this.searchController,
    required this.statusFilter,
    required this.onStatusFilterChanged,
    required this.onRefresh,
    required this.onCreate,
    required this.onSearchSubmitted,
  });

  final TextEditingController searchController;
  final String statusFilter;
  final ValueChanged<String?> onStatusFilterChanged;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;
  final ValueChanged<String> onSearchSubmitted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onSubmitted: onSearchSubmitted,
          ),
        ),
        const SizedBox(width: 10),
        DropdownButton<String>(
          value: statusFilter,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All')),
            DropdownMenuItem(value: 'active', child: Text('Active')),
            DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
          ],
          onChanged: onStatusFilterChanged,
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add),
          label: const Text('Create'),
        ),
      ],
    );
  }
}
