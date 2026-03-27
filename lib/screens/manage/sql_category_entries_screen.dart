import 'package:flutter/material.dart';

class SqlCategoryEntriesScreen extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> rows;
  final List<String> columns;

  const SqlCategoryEntriesScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.rows,
    required this.columns,
  });

  @override
  State<SqlCategoryEntriesScreen> createState() =>
      _SqlCategoryEntriesScreenState();
}

class _SqlCategoryEntriesScreenState extends State<SqlCategoryEntriesScreen> {
  late final TextEditingController _searchController;
  late String _selectedFilterColumn;
  late String _selectedSortColumn;
  int? _sortColumnIndex;
  bool _ascending = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedFilterColumn = widget.columns.first;
    _selectedSortColumn = widget.columns.first;
    _sortColumnIndex = 0;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _processedRows {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = widget.rows.where((row) {
      if (query.isEmpty) return true;
      final value = row[_selectedFilterColumn]?.toString().toLowerCase() ?? '';
      return value.contains(query);
    }).toList();

    filtered.sort((a, b) {
      final left = a[_selectedSortColumn]?.toString().toLowerCase() ?? '';
      final right = b[_selectedSortColumn]?.toString().toLowerCase() ?? '';
      return _ascending ? left.compareTo(right) : right.compareTo(left);
    });

    return filtered;
  }

  void _handleColumnSort(int columnIndex) {
    final selectedColumn = widget.columns[columnIndex];
    final isSameColumn = _selectedSortColumn == selectedColumn;

    setState(() {
      _selectedSortColumn = selectedColumn;
      _sortColumnIndex = columnIndex;
      _ascending = isSameColumn ? !_ascending : true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rows = _processedRows;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedFilterColumn,
                    decoration: const InputDecoration(
                      labelText: 'Filter Column',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: widget.columns
                        .map((column) => DropdownMenuItem<String>(
                              value: column,
                              child: Text(column),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedFilterColumn = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                  'Tip: tap any column heading to sort ascending/descending.'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                Icon(widget.icon, size: 18),
                const SizedBox(width: 8),
                Text('Total: ${rows.length} records'),
              ],
            ),
          ),
          Expanded(
            child: rows.isEmpty
                ? const Center(
                    child: Text('No records found for current search/filter.'),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        sortColumnIndex: _sortColumnIndex,
                        sortAscending: _ascending,
                        columns: widget.columns
                            .asMap()
                            .entries
                            .map(
                              (entry) => DataColumn(
                                label: Text(entry.value),
                                onSort: (_, __) => _handleColumnSort(entry.key),
                              ),
                            )
                            .toList(),
                        rows: rows
                            .map(
                              (row) => DataRow(
                                cells: widget.columns
                                    .map(
                                      (column) => DataCell(
                                        Text('${row[column] ?? '-'}'),
                                      ),
                                    )
                                    .toList(),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
