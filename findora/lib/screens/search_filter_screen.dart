import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../widgets/item_card.dart';
import 'item_detail_screen.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  String _selectedColor = 'Any';
  DateTimeRange? _dateRange;
  bool _showFilters = false;

  final List<String> _categories = [
    'All',
    'Electronics',
    'Documents',
    'Keys',
    'Bags & Wallets',
    'Clothing',
    'Accessories',
    'Books',
    'Other',
  ];
  final List<String> _colors = [
    'Any',
    'Black',
    'White',
    'Blue',
    'Red',
    'Brown',
    'Silver',
    'Yellow',
    'Green',
    'Other',
  ];
  final List<String> _statuses = ['All', 'Lost', 'Found'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ItemModel> get _results {
    return dummyItems.where((item) {
      final matchQuery =
          _query.isEmpty ||
          item.title.toLowerCase().contains(_query.toLowerCase()) ||
          item.description.toLowerCase().contains(_query.toLowerCase()) ||
          item.location.toLowerCase().contains(_query.toLowerCase());
      final matchCat =
          _selectedCategory == 'All' || item.category == _selectedCategory;
      final matchStatus =
          _selectedStatus == 'All' ||
          (item.status == ItemStatus.lost && _selectedStatus == 'Lost') ||
          (item.status == ItemStatus.found && _selectedStatus == 'Found');
      final matchColor =
          _selectedColor == 'Any' ||
          (item.color?.toLowerCase() == _selectedColor.toLowerCase());
      return matchQuery && matchCat && matchStatus && matchColor;
    }).toList();
  }

  bool get _hasActiveFilters =>
      _selectedCategory != 'All' ||
      _selectedStatus != 'All' ||
      _selectedColor != 'Any' ||
      _dateRange != null;

  void _clearFilters() {
    setState(() {
      _selectedCategory = 'All';
      _selectedStatus = 'All';
      _selectedColor = 'Any';
      _dateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(context),
          if (_showFilters) _buildFilterPanel(),
          _buildResultsBar(),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Search & Filter',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Search bar
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search by name, location, category...',
                          hintStyle: TextStyle(
                            color: Color(0xFFBEC5CF),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: Color(0xFF94A3B8),
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                    GestureDetector(
                      onTap: () => setState(() => _showFilters = !_showFilters),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: _hasActiveFilters
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: _hasActiveFilters
                              ? Colors.white
                              : const Color(0xFF2563EB),
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (_hasActiveFilters)
                GestureDetector(
                  onTap: _clearFilters,
                  child: const Text(
                    'Clear all',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Status
          _filterLabel('Status'),
          const SizedBox(height: 8),
          _buildChipRow(
            items: _statuses,
            selected: _selectedStatus,
            onSelect: (v) => setState(() => _selectedStatus = v),
          ),
          const SizedBox(height: 14),

          // Category
          _filterLabel('Category'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final sel = cat == _selectedCategory;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : const Color(0xFF374151),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Color
          _filterLabel('Color'),
          const SizedBox(height: 8),
          _buildColorRow(),
          const SizedBox(height: 14),

          // Date range
          _filterLabel('Date Range'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF2563EB),
                    ),
                  ),
                  child: child!,
                ),
              );
              if (range != null) setState(() => _dateRange = range);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _dateRange != null
                    ? const Color(0xFFEFF6FF)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _dateRange != null
                      ? const Color(0xFF2563EB)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: _dateRange != null
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _dateRange != null
                        ? '${_fmt(_dateRange!.start)} – ${_fmt(_dateRange!.end)}'
                        : 'Select date range',
                    style: TextStyle(
                      fontSize: 13,
                      color: _dateRange != null
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF64748B),
                      fontWeight: _dateRange != null
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  if (_dateRange != null) ...[
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _dateRange = null),
                      child: const Icon(
                        Icons.clear_rounded,
                        size: 14,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Widget _filterLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
    );
  }

  Widget _buildChipRow({
    required List<String> items,
    required String selected,
    required Function(String) onSelect,
  }) {
    return Row(
      children: items.map((item) {
        final sel = item == selected;
        return GestureDetector(
          onTap: () => onSelect(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: sel ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorRow() {
    final colorMap = {
      'Any': Colors.grey.shade300,
      'Black': Colors.black,
      'White': Colors.white,
      'Blue': Colors.blue,
      'Red': Colors.red,
      'Brown': Colors.brown,
      'Silver': Colors.blueGrey.shade300,
      'Yellow': Colors.amber,
      'Green': Colors.green,
      'Other': Colors.purple.shade200,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _colors.map((color) {
          final sel = color == _selectedColor;
          return GestureDetector(
            onTap: () => setState(() => _selectedColor = color),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colorMap[color],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: sel
                            ? const Color(0xFF2563EB)
                            : Colors.grey.shade300,
                        width: sel ? 2.5 : 1,
                      ),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.3),
                                blurRadius: 6,
                              ),
                            ]
                          : [],
                    ),
                    child: sel
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Color(0xFF2563EB),
                          )
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    color,
                    style: TextStyle(
                      fontSize: 10,
                      color: sel
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF94A3B8),
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultsBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Text(
            '${_results.length} result${_results.length != 1 ? 's' : ''}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Filtered',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _showFilters = !_showFilters),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _showFilters
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: const Color(0xFF2563EB),
                ),
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_query.isEmpty && !_hasActiveFilters) {
      return _buildEmptySearch();
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try different keywords or filters',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      itemCount: _results.length,
      itemBuilder: (_, i) => ItemCard(
        item: _results[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ItemDetailScreen(item: _results[i], isGuest: false),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySearch() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Popular searches',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                  'iPhone',
                  'Wallet',
                  'Keys',
                  'ID Card',
                  'Backpack',
                  'Airpods',
                  'Glasses',
                  'Books',
                ].map((tag) {
                  return GestureDetector(
                    onTap: () {
                      _searchController.text = tag;
                      setState(() => _query = tag);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            size: 13,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF374151),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Recent items',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          ...dummyItems
              .take(3)
              .map(
                (item) => ItemCard(
                  item: item,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ItemDetailScreen(item: item, isGuest: false),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
