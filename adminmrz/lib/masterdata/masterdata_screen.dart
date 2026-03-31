import 'dart:convert';
import 'package:adminmrz/core/app_constants.dart';
import 'package:adminmrz/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MasterDataScreen extends StatefulWidget {
  const MasterDataScreen({super.key});

  @override
  State<MasterDataScreen> createState() => _MasterDataScreenState();
}

class _MasterDataCategory {
  final String label;
  final String getEndpoint;
  final String insertUpdateEndpoint;
  final String toggleEndpoint;
  final String valueKey;

  const _MasterDataCategory({
    required this.label,
    required this.getEndpoint,
    required this.insertUpdateEndpoint,
    required this.toggleEndpoint,
    required this.valueKey,
  });
}

class _MasterDataScreenState extends State<MasterDataScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<_MasterDataCategory> _categories = [
    _MasterDataCategory(
      label: 'Religion',
      getEndpoint: '/admin/religion/getReligion',
      insertUpdateEndpoint: '/admin/religion/insertUpdateReligion',
      toggleEndpoint: '/admin/religion/activeInactiveReligion',
      valueKey: 'name',
    ),
    _MasterDataCategory(
      label: 'Diet',
      getEndpoint: '/admin/diet/getDiet',
      insertUpdateEndpoint: '/admin/diet/insertUpdateDiet',
      toggleEndpoint: '/admin/diet/activeInactiveDiet',
      valueKey: 'name',
    ),
    _MasterDataCategory(
      label: 'Marital Status',
      getEndpoint: '/admin/maritalStatus/getMaritalStatus',
      insertUpdateEndpoint: '/admin/maritalStatus/insertUpdateMaritalStatus',
      toggleEndpoint: '/admin/maritalStatus/activeInactiveMaritalStatus',
      valueKey: 'name',
    ),
    _MasterDataCategory(
      label: 'Occupation',
      getEndpoint: '/admin/occupation/getOccupation',
      insertUpdateEndpoint: '/admin/occupation/insertUpdateOccupation',
      toggleEndpoint: '/admin/occupation/activeInactiveOccupation',
      valueKey: 'name',
    ),
    _MasterDataCategory(
      label: 'Annual Income',
      getEndpoint: '/admin/annualIncome/getAnnualIncome',
      insertUpdateEndpoint: '/admin/annualIncome/insertUpdateAnnualIncome',
      toggleEndpoint: '/admin/annualIncome/activeInactiveAnnualIncome',
      valueKey: 'value',
    ),
    _MasterDataCategory(
      label: 'Education',
      getEndpoint: '/admin/education/getEducation',
      insertUpdateEndpoint: '/admin/education/insertUpdateEducation',
      toggleEndpoint: '/admin/education/activeInactiveEducation',
      valueKey: 'name',
    ),
    _MasterDataCategory(
      label: 'Height',
      getEndpoint: '/admin/height/getHeight',
      insertUpdateEndpoint: '/admin/height/insertUpdateHeight',
      toggleEndpoint: '/admin/height/activeInactiveHeight',
      valueKey: 'value',
    ),
    _MasterDataCategory(
      label: 'Weight',
      getEndpoint: '/admin/weight/getWeight',
      insertUpdateEndpoint: '/admin/weight/insertUpdateWeight',
      toggleEndpoint: '/admin/weight/activeInactiveWeight',
      valueKey: 'value',
    ),
    _MasterDataCategory(
      label: 'Employment Type',
      getEndpoint: '/admin/employmentType/getEmploymentType',
      insertUpdateEndpoint: '/admin/employmentType/insertUpdateEmploymentType',
      toggleEndpoint: '/admin/employmentType/activeInactiveEmploymentType',
      valueKey: 'name',
    ),
    _MasterDataCategory(
      label: 'Community',
      getEndpoint: '/admin/community/getCommunity',
      insertUpdateEndpoint: '/admin/community/insertUpdateCommunity',
      toggleEndpoint: '/admin/community/activeInactiveCommunity',
      valueKey: 'name',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppTheme.cardBg,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: _categories.map((c) => Tab(text: c.label)).toList(),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _categories
                .map((cat) => _MasterDataTabView(category: cat))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _MasterDataTabView extends StatefulWidget {
  final _MasterDataCategory category;
  const _MasterDataTabView({required this.category});

  @override
  State<_MasterDataTabView> createState() => _MasterDataTabViewState();
}

class _MasterDataItem {
  final int id;
  final String value;
  final int isActive;

  _MasterDataItem({required this.id, required this.value, required this.isActive});
}

class _MasterDataTabViewState extends State<_MasterDataTabView>
    with AutomaticKeepAliveClientMixin {
  List<_MasterDataItem> _items = [];
  List<_MasterDataItem> _filtered = [];
  bool _isLoading = false;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_items)
          : _items.where((i) => i.value.toLowerCase().contains(q)).toList();
    });
  }

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.apiBaseUrl}${widget.category.getEndpoint}'),
            headers: await _authHeaders(),
            body: json.encode({'startIndex': 0, 'fetchRecord': 100}),
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'];
        if (status == 200 || status?.toString() == '200') {
          final records = (data['recordList'] ?? []) as List;
          final vk = widget.category.valueKey;
          setState(() {
            _items = records
                .map((r) => _MasterDataItem(
                      id: r['id'] is int ? r['id'] : int.tryParse(r['id']?.toString() ?? '') ?? 0,
                      value: r[vk]?.toString() ?? r['name']?.toString() ?? r['value']?.toString() ?? '',
                      isActive: r['isActive'] is int ? r['isActive'] : int.tryParse(r['isActive']?.toString() ?? '') ?? 1,
                    ))
                .toList();
            _filtered = List.from(_items);
          });
        } else {
          setState(() => _error = data['message']?.toString() ?? 'Failed to load');
        }
      } else {
        setState(() => _error = 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleItem(_MasterDataItem item) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.apiBaseUrl}${widget.category.toggleEndpoint}'),
            headers: await _authHeaders(),
            body: json.encode({'id': item.id}),
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'];
        if (status == 200 || status?.toString() == '200') {
          await _fetchData();
        } else {
          _showSnack(data['message']?.toString() ?? 'Failed to toggle');
        }
      }
    } catch (e) {
      _showSnack('Error: $e');
    }
  }

  Future<void> _saveItem({int? id, required String value}) async {
    try {
      final vk = widget.category.valueKey;
      final body = <String, dynamic>{vk: value};
      if (id != null) body['id'] = id;

      final response = await http
          .post(
            Uri.parse('${AppConstants.apiBaseUrl}${widget.category.insertUpdateEndpoint}'),
            headers: await _authHeaders(),
            body: json.encode(body),
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'];
        if (status == 200 || status?.toString() == '200') {
          await _fetchData();
          _showSnack(id == null ? 'Added successfully' : 'Updated successfully');
        } else {
          _showSnack(data['message']?.toString() ?? 'Failed to save');
        }
      }
    } catch (e) {
      _showSnack('Error: $e');
    }
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _showEditDialog({_MasterDataItem? item}) {
    final ctrl = TextEditingController(text: item?.value ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          item == null ? 'Add ${widget.category.label}' : 'Edit ${widget.category.label}',
          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: widget.category.label,
            border: OutlineInputBorder(borderRadius: AppTheme.radiusSm),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppTheme.radiusSm,
              borderSide: const BorderSide(color: AppTheme.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isNotEmpty) {
                Navigator.pop(ctx);
                _saveItem(id: item?.id, value: v);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search ${widget.category.label}...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: AppTheme.radiusSm,
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showEditDialog(),
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text('Add', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: AppTheme.primary)))
          else if (_error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, style: const TextStyle(color: AppTheme.error)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _fetchData,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                      child: const Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: AppTheme.radiusMd,
                  border: Border.all(color: AppTheme.borderLight),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: _filtered.isEmpty
                    ? const Center(
                        child: Text('No items found', style: TextStyle(color: AppTheme.textMuted)),
                      )
                    : ListView.separated(
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.borderLight),
                        itemBuilder: (ctx, i) {
                          final item = _filtered[i];
                          return ListTile(
                            title: Text(
                              item.value,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              'ID: ${item.id}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: item.isActive == 1,
                                  activeColor: AppTheme.primary,
                                  onChanged: (_) => _toggleItem(item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  color: AppTheme.textSecondary,
                                  onPressed: () => _showEditDialog(item: item),
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
    );
  }
}
