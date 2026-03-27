import 'package:flutter/material.dart';

import '../../modules/masters/models/master_item.dart';
import 'app_footer.dart';
import 'app_header.dart';
import 'crud_toolbar.dart';
import 'module_page_header.dart';
import 'page_container.dart';

typedef FetchItemsPage = Future<List<MasterItem>> Function(
  String query,
  int page,
  int perPage,
  String statusFilter,
  String sort,
  String order,
);
typedef MutateItem = Future<void> Function(String name, bool isActive);
typedef UpdateItem = Future<void> Function(int id, String name, bool isActive);
typedef DeleteItem = Future<void> Function(int id);

class BaseCrudScreen extends StatefulWidget {
  const BaseCrudScreen({
    super.key,
    required this.title,
    required this.fetchItemsPage,
    required this.createItem,
    required this.updateItem,
    required this.deleteItem,
  });

  final String title;
  final FetchItemsPage fetchItemsPage;
  final MutateItem createItem;
  final UpdateItem updateItem;
  final DeleteItem deleteItem;

  @override
  State<BaseCrudScreen> createState() => _BaseCrudScreenState();
}

class _BaseCrudScreenState extends State<BaseCrudScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  List<MasterItem> _rows = [];
  int _page = 1;
  static const int _perPage = 20;
  String _statusFilter = 'all';
  String _sort = 'name';
  String _order = 'asc';

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients || _loadingMore || !_hasMore) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 180) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _page = 1;
      _hasMore = true;
    });
    try {
      final first = await widget.fetchItemsPage(
        _searchCtrl.text,
        _page,
        _perPage,
        _statusFilter,
        _sort,
        _order,
      );
      _rows = first;
      _hasMore = first.length == _perPage;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final next = await widget.fetchItemsPage(
        _searchCtrl.text,
        nextPage,
        _perPage,
        _statusFilter,
        _sort,
        _order,
      );
      if (!mounted) return;
      setState(() {
        _rows = [..._rows, ...next];
        _page = nextPage;
        _hasMore = next.length == _perPage;
      });
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _toggleSort(String sortKey) {
    setState(() {
      if (_sort == sortKey) {
        _order = _order == 'asc' ? 'desc' : 'asc';
      } else {
        _sort = sortKey;
        _order = 'asc';
      }
    });
    _load();
  }

  Widget _sortableHeader(String label, String sortKey, {int flex = 1}) {
    final isActive = _sort == sortKey;
    final icon = _order == 'asc' ? Icons.arrow_upward : Icons.arrow_downward;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => _toggleSort(sortKey),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 14),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _createOrEdit({MasterItem? existing}) async {
    final ctrl = TextEditingController(text: existing?.name ?? '');
    bool isActive = existing?.isActive ?? true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(existing == null ? 'Create ${widget.title}' : 'Edit ${widget.title}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(labelText: 'Name'),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: isActive,
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                onChanged: (v) => setDialog(() => isActive = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result != true) return;
    final name = ctrl.text.trim();
    if (name.isEmpty) return;
    if (existing == null) {
      await widget.createItem(name, isActive);
    } else {
      await widget.updateItem(existing.id, name, isActive);
    }
    await _load();
  }

  Future<void> _delete(MasterItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confirm Delete',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text('Delete "${item.name}"? This action cannot be undone.'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;
    await widget.deleteItem(item.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: ModulePageHeader(
                  title: widget.title,
                  breadcrumbs: ['MASTER', widget.title],
                ),
              ),
            ),
          ),
          Expanded(
            child: PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  CrudToolbar(
                    searchController: _searchCtrl,
                    statusFilter: _statusFilter,
                    onStatusFilterChanged: (v) {
                      if (v == null) return;
                      setState(() => _statusFilter = v);
                      _load();
                    },
                    onRefresh: _load,
                    onCreate: () => _createOrEdit(),
                    onSearchSubmitted: (_) => _load(),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0x1A000000)),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              _sortableHeader('ID', 'id', flex: 1),
                              _sortableHeader('Name', 'name', flex: 4),
                              const Expanded(flex: 2, child: Text('Status')),
                              const Expanded(flex: 3, child: Text('Actions')),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Scrollbar(
                            controller: _scrollCtrl,
                            child: ListView.separated(
                              controller: _scrollCtrl,
                              itemCount: _rows.length,
                              separatorBuilder: (context, index) => const Divider(
                                height: 1,
                                color: Color(0x1A000000),
                              ),
                              itemBuilder: (context, index) {
                                final item = _rows[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Text(item.id.toString()),
                                      ),
                                      Expanded(
                                        flex: 4,
                                        child: Text(item.name),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: item.isActive
                                                  ? Colors.green.shade100
                                                  : Colors.grey.shade300,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              item.isActive ? 'Active' : 'Inactive',
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          children: [
                                            IconButton(
                                              onPressed: () =>
                                                  _createOrEdit(existing: item),
                                              icon: const Icon(Icons.edit),
                                            ),
                                            IconButton(
                                              onPressed: () => _delete(item),
                                              icon: const Icon(Icons.delete),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_loadingMore)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }
}
