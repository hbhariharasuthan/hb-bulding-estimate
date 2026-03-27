import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../shared/widgets/app_footer.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/module_page_header.dart';
import '../models/master_item.dart';
import '../models/material_standard_item.dart';
import '../repositories/master_repository.dart';

class MaterialStandardsPage extends StatefulWidget {
  const MaterialStandardsPage({super.key});

  @override
  State<MaterialStandardsPage> createState() => _MaterialStandardsPageState();
}

class _MaterialStandardsPageState extends State<MaterialStandardsPage> {
  final _repo = GetIt.I<MasterRepository>();
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  static const int _perPage = 20;
  String _statusFilter = 'all';
  String _sort = 'id';
  String _order = 'asc';
  List<MaterialStandardItem> _rows = [];
  List<MasterItem> _materials = [];
  List<MasterItem> _properties = [];
  List<MasterItem> _units = [];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadAll();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients || _loadingMore || !_hasMore || _loading) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _page = 1;
      _hasMore = true;
    });
    try {
      final dropdowns = await _repo.fetchDropdowns();
      _materials = dropdowns['materials'] ?? [];
      _properties = dropdowns['properties'] ?? [];
      _units = dropdowns['units'] ?? [];
      _rows = await _repo.listStandards(
        q: _searchCtrl.text,
        page: _page,
        perPage: _perPage,
        statusFilter: _statusFilter,
        sort: _sort,
        order: _order,
      );
      _hasMore = _rows.length == _perPage;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final next = await _repo.listStandards(
        q: _searchCtrl.text,
        page: nextPage,
        perPage: _perPage,
        statusFilter: _statusFilter,
        sort: _sort,
        order: _order,
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

  Future<void> _openForm({MaterialStandardItem? existing}) async {
    int? selectedMaterialId = existing?.materialId ?? (_materials.isNotEmpty ? _materials.first.id : null);
    int? selectedPropertyId = existing?.propertyId ?? (_properties.isNotEmpty ? _properties.first.id : null);
    int? selectedUnitId = existing?.unitId ?? (_units.isNotEmpty ? _units.first.id : null);
    final valueCtrl = TextEditingController(text: existing?.value?.toString() ?? '');
    bool isDefault = existing?.isDefault ?? true;
    bool isActive = existing?.isActive ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(existing == null ? 'Create MATERIAL STANDARD' : 'Edit MATERIAL STANDARD'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedMaterialId,
                  decoration: const InputDecoration(labelText: 'Material'),
                  items: _materials
                      .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))
                      .toList(),
                  onChanged: existing == null ? (v) => setDialog(() => selectedMaterialId = v) : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: selectedPropertyId,
                  decoration: const InputDecoration(labelText: 'Property'),
                  items: _properties
                      .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                      .toList(),
                  onChanged: existing == null ? (v) => setDialog(() => selectedPropertyId = v) : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: selectedUnitId,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: _units.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))).toList(),
                  onChanged: (v) => setDialog(() => selectedUnitId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: valueCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Value (optional)'),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: isDefault,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Default'),
                  onChanged: (v) => setDialog(() => isDefault = v ?? false),
                ),
                CheckboxListTile(
                  value: isActive,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  onChanged: (v) => setDialog(() => isActive = v ?? false),
                ),
              ],
            ),
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

    if (ok != true || selectedUnitId == null) return;
    final parsedValue = valueCtrl.text.trim().isEmpty ? null : double.tryParse(valueCtrl.text.trim());
    if (existing == null) {
      if (selectedMaterialId == null || selectedPropertyId == null) return;
      await _repo.createStandard(
        materialId: selectedMaterialId!,
        propertyId: selectedPropertyId!,
        unitId: selectedUnitId!,
        value: parsedValue,
        isDefault: isDefault,
        isActive: isActive,
      );
    } else {
      await _repo.updateStandard(
        standardId: existing.standardId,
        unitId: selectedUnitId!,
        value: parsedValue,
        isDefault: isDefault,
        isActive: isActive,
      );
    }
    await _loadAll();
  }

  Future<void> _delete(MaterialStandardItem row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete confirmation'),
        content: Text('Delete ${row.materialName} / ${row.propertyName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await _repo.deleteStandard(row.standardId);
    await _loadAll();
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
    _loadAll();
  }

  Widget _sortableHeader(String label, String sortKey) {
    final active = _sort == sortKey;
    final icon = _order == 'asc' ? Icons.arrow_upward : Icons.arrow_downward;
    return InkWell(
      onTap: () => _toggleSort(sortKey),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: active ? FontWeight.w700 : FontWeight.w500),
          ),
          if (active) ...[
            const SizedBox(width: 4),
            Icon(icon, size: 14),
          ],
        ],
      ),
    );
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
              constraints: const BoxConstraints(maxWidth: 1300),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: ModulePageHeader(
                  title: 'Material Standards',
                  breadcrumbs: ['MASTER', 'MATERIAL STANDARDS'],
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1300),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                        const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Search by material/property/unit...',
                                prefixIcon: Icon(Icons.search),
                              ),
                              onSubmitted: (_) => _loadAll(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          DropdownButton<String>(
                            value: _statusFilter,
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All')),
                              DropdownMenuItem(value: 'active', child: Text('Active')),
                              DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _statusFilter = value);
                              _loadAll();
                            },
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _loadAll,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: _materials.isEmpty || _properties.isEmpty || _units.isEmpty
                                ? null
                                : () => _openForm(),
                            icon: const Icon(Icons.add),
                            label: const Text('Create'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: _loading
                            ? const Center(child: CircularProgressIndicator())
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  return SingleChildScrollView(
                                    controller: _scrollCtrl,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                        child: DataTable(
                                          columns: [
                                            DataColumn(label: _sortableHeader('ID', 'id')),
                                            DataColumn(label: _sortableHeader('Material', 'material')),
                                            DataColumn(label: _sortableHeader('Property', 'property')),
                                            const DataColumn(label: Text('Value')),
                                            const DataColumn(label: Text('Unit')),
                                            const DataColumn(label: Text('Status')),
                                            const DataColumn(label: Text('Actions')),
                                          ],
                                          headingRowHeight: 56,
                                          rows: _rows
                                              .map(
                                                (row) => DataRow(cells: [
                                                  DataCell(Text(row.standardId.toString())),
                                                  DataCell(Text(row.materialName)),
                                                  DataCell(Text(row.propertyName)),
                                                  DataCell(Text(row.value?.toString() ?? '—')),
                                                  DataCell(Text(row.unitName)),
                                                  DataCell(Text(row.isActive ? 'Active' : 'Inactive')),
                                                  DataCell(
                                                    Row(
                                                      children: [
                                                        IconButton(
                                                          onPressed: () => _openForm(existing: row),
                                                          icon: const Icon(Icons.edit),
                                                        ),
                                                        IconButton(
                                                          onPressed: () => _delete(row),
                                                          icon: const Icon(Icons.delete_forever),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ]),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      if (_loadingMore)
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }
}
