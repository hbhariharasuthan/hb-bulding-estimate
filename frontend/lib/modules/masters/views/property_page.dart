import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../shared/widgets/base_crud_screen.dart';
import '../repositories/master_repository.dart';

class PropertyPage extends StatelessWidget {
  const PropertyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = GetIt.I<MasterRepository>();
    const path = '/api/v1/material-standards/properties';
    return BaseCrudScreen(
      title: 'Property',
      fetchItemsPage: (q, page, perPage, statusFilter, sort, order) => repo.list(
        path,
        q: q,
        page: page,
        perPage: perPage,
        statusFilter: statusFilter,
        sort: sort,
        order: order,
      ),
      createItem: (name, isActive) => repo.create(path, name, isActive: isActive),
      updateItem: (id, name, isActive) => repo.update(path, id, name, isActive: isActive),
      deleteItem: (id) => repo.delete(path, id),
    );
  }
}
