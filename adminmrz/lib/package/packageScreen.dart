import 'package:adminmrz/package/packageProvider.dart';
import 'package:adminmrz/package/packagemodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class PackagesPage extends StatefulWidget {
  const PackagesPage({Key? key}) : super(key: key);

  @override
  State<PackagesPage> createState() => _PackagesPageState();
}

class _PackagesPageState extends State<PackagesPage> {
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  Package? _editingPackage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PackageProvider>().fetchPackages();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _showCreatePackageDialog() {
    _editingPackage = null;
    _nameController.clear();
    _durationController.clear();
    _descriptionController.clear();
    _priceController.clear();

    showDialog(
      context: context,
      builder: (context) => _buildPackageDialog(isEdit: false),
    );
  }

  void _showEditPackageDialog(Package package) {
    _editingPackage = package;
    _nameController.text = package.name;
    _durationController.text = package.durationInMonths.toString();
    _descriptionController.text = package.description;
    _priceController.text = package.numericPrice.toString();

    showDialog(
      context: context,
      builder: (context) => _buildPackageDialog(isEdit: true),
    );
  }

  Widget _buildPackageDialog({required bool isEdit}) {
    return AlertDialog(
      title: Text(isEdit ? 'Edit Package' : 'Create New Package'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Package Name',
                  hintText: 'e.g., Diamond, Gold, Silver',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter package name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (Months)',
                  hintText: 'e.g., 30, 90',
                  border: OutlineInputBorder(),
                  suffixText: 'Months',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter duration';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g., Premium plan with unlimited access',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  hintText: 'e.g., 300.00',
                  border: OutlineInputBorder(),
                  prefixText: 'Rs ',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _handleSavePackage(isEdit),
          child: Text(isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  Future<void> _handleSavePackage(bool isEdit) async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<PackageProvider>();

    if (isEdit && _editingPackage != null) {
      // Update existing package
      final updatedPackage = Package(
        id: _editingPackage!.id,
        name: _nameController.text.trim(),
        duration: '${_durationController.text.trim()} Month',
        description: _descriptionController.text.trim(),
        price: 'Rs ${double.parse(_priceController.text.trim()).toStringAsFixed(2)}',
      );

      final success = await provider.updatePackage(updatedPackage);

      if (success) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Package updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${provider.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Create new package
      final success = await provider.createPackage(
        name: _nameController.text.trim(),
        duration: int.parse(_durationController.text.trim()),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
      );

      if (success) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Package created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${provider.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeleteDialog(Package package) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Package'),
        content: Text(
            'Are you sure you want to delete "${package.name}" package? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<PackageProvider>();
      final success = await provider.deletePackage(package.id);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Package deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${provider.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildPackageCard(Package package) {
    Color? cardColor;
    IconData? packageIcon;

    // Assign colors and icons based on package name
    switch (package.name.toLowerCase()) {
      case 'diamond':
        cardColor = Colors.blue.shade50;
        packageIcon = Icons.diamond;
        break;
      case 'gold':
        cardColor = Colors.amber.shade50;
        packageIcon = Icons.star;
        break;
      case 'silver':
        cardColor = Colors.grey.shade50;
        packageIcon = Icons.workspace_premium;
        break;
      default:
        cardColor = Colors.grey.shade50;
        packageIcon = Icons.card_membership;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardColor!,
              cardColor.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(packageIcon, color: Colors.blue, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        package.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      package.duration,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                package.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    package.price,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _showEditPackageDialog(package),
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        onPressed: () => _showDeleteDialog(package),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context, PackageProvider provider) {
    // Calculate statistics
    final totalPackages = provider.allPackages.length;
    final totalRevenue = provider.allPackages.fold<double>(
      0,
          (sum, package) => sum + package.numericPrice,
    );
    final avgPrice = totalPackages > 0 ? totalRevenue / totalPackages : 0;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Package Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Packages',
                    totalPackages.toString(),
                    Icons.widgets,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Average Price',
                    'Rs ${avgPrice.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total Revenue',
                    'Rs ${totalRevenue.toStringAsFixed(2)}',
                    Icons.bar_chart,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.card_membership,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'No Packages Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Create your first package to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showCreatePackageDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Package'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PackageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Package Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.fetchPackages(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePackageDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Package'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search packages...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    provider.setSearchQuery('');
                  },
                )
                    : null,
              ),
              onChanged: provider.setSearchQuery,
            ),
          ),

          // Statistics
          _buildStats(context, provider),

          // Package List
          Expanded(
            child: provider.packages.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: () => provider.fetchPackages(),
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: provider.packages.length,
                itemBuilder: (context, index) {
                  final package = provider.packages[index];
                  return _buildPackageCard(package);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}