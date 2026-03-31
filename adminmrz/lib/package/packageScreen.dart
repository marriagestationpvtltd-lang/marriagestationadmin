import 'package:adminmrz/package/packageProvider.dart';
import 'package:adminmrz/package/packagemodel.dart';
import 'package:adminmrz/theme/app_theme.dart';
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

  // ── Dialog helpers ───────────────────────────────────────────────────────────

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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusLg),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: AppTheme.radiusLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dialog header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEdit ? Icons.edit_rounded : Icons.add_circle_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? 'Edit Package' : 'Create New Package',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white70, size: 20),
                  ),
                ],
              ),
            ),

            // Form fields
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDialogField(
                      controller: _nameController,
                      label: 'Package Name',
                      hint: 'e.g., Diamond, Gold, Silver',
                      icon: Icons.workspace_premium_rounded,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Please enter package name' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildDialogField(
                      controller: _durationController,
                      label: 'Duration (Months)',
                      hint: 'e.g., 1, 3, 6, 12',
                      icon: Icons.schedule_rounded,
                      suffix: 'Months',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter duration';
                        if (int.tryParse(v) == null) return 'Enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildDialogField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'e.g., Premium plan with unlimited access',
                      icon: Icons.description_rounded,
                      maxLines: 3,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Please enter description' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildDialogField(
                      controller: _priceController,
                      label: 'Price',
                      hint: '300.00',
                      icon: Icons.currency_rupee_rounded,
                      prefix: 'Rs ',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter price';
                        if (double.tryParse(v) == null) return 'Enter a valid price';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: const BorderSide(color: AppTheme.border),
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppTheme.radiusSm),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleSavePackage(isEdit),
                      icon: Icon(
                          isEdit ? Icons.save_rounded : Icons.add_rounded,
                          size: 16),
                      label: Text(isEdit ? 'Update Package' : 'Create Package'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppTheme.radiusSm),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? suffix,
    String? prefix,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            prefixIcon: Icon(icon, size: 18, color: AppTheme.primary),
            prefixText: prefix,
            prefixStyle: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            suffixText: suffix,
            suffixStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: AppTheme.radiusSm,
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppTheme.radiusSm,
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppTheme.radiusSm,
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppTheme.radiusSm,
              borderSide: const BorderSide(color: AppTheme.error),
            ),
            filled: true,
            fillColor: const Color(0xFFFDF5F7),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  // ── Logic (unchanged) ────────────────────────────────────────────────────────

  Future<void> _handleSavePackage(bool isEdit) async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<PackageProvider>();

    if (isEdit && _editingPackage != null) {
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
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${provider.error}'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    } else {
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
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${provider.error}'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeleteDialog(Package package) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusLg),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: AppTheme.radiusLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.errorLight,
                  borderRadius: AppTheme.radiusXl,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete Package',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete "${package.name}"? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: const BorderSide(color: AppTheme.border),
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppTheme.radiusSm),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.delete_rounded, size: 16),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppTheme.radiusSm),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${provider.error}'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  // ── Package Card ─────────────────────────────────────────────────────────────

  LinearGradient _packageGradient(String name) {
    switch (name.toLowerCase()) {
      case 'diamond':
        return AppTheme.blueGradient;
      case 'gold':
        return AppTheme.goldGradient;
      case 'platinum':
        return AppTheme.purpleGradient;
      case 'silver':
        return const LinearGradient(
          colors: [Color(0xFF78909C), Color(0xFF546E7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return AppTheme.primaryGradient;
    }
  }

  IconData _packageIcon(String name) {
    switch (name.toLowerCase()) {
      case 'diamond':
        return Icons.diamond_rounded;
      case 'gold':
        return Icons.star_rounded;
      case 'platinum':
        return Icons.workspace_premium_rounded;
      case 'silver':
        return Icons.military_tech_rounded;
      default:
        return Icons.card_membership_rounded;
    }
  }

  Widget _buildPackageCard(Package package) {
    final gradient = _packageGradient(package.name);
    final icon = _packageIcon(package.name);

    // Parse description into bullet points
    final bullets = package.description
        .split(RegExp(r'[,.\n]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: AppTheme.radiusLg,
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: AppTheme.radiusMd,
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: AppTheme.radiusSm,
                        ),
                        child: Text(
                          package.duration,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Price badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppTheme.radiusMd,
                  ),
                  child: Text(
                    package.price,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.success,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body: bullet features + actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Feature bullets
                if (bullets.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.list_rounded,
                          size: 14, color: AppTheme.primary),
                      const SizedBox(width: 5),
                      Text(
                        'Features',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...bullets.take(4).map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: CircleAvatar(
                                radius: 3,
                                backgroundColor: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                b,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 8),
                  Divider(color: AppTheme.borderLight, height: 1),
                  const SizedBox(height: 12),
                ],

                // Action row
                Row(
                  children: [
                    _buildActionButton(
                      label: 'Edit',
                      icon: Icons.edit_rounded,
                      color: AppTheme.info,
                      bgColor: AppTheme.infoLight,
                      onTap: () => _showEditPackageDialog(package),
                    ),
                    const SizedBox(width: 10),
                    _buildActionButton(
                      label: 'Delete',
                      icon: Icons.delete_rounded,
                      color: AppTheme.error,
                      bgColor: AppTheme.errorLight,
                      onTap: () => _showDeleteDialog(package),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppTheme.radiusSm,
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats ────────────────────────────────────────────────────────────────────

  Widget _buildStats(BuildContext context, PackageProvider provider) {
    final totalPackages = provider.allPackages.length;
    final totalRevenue = provider.allPackages.fold<double>(
      0,
      (sum, package) => sum + package.numericPrice,
    );
    final avgPrice = totalPackages > 0 ? totalRevenue / totalPackages : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              label: 'Total Packages',
              value: totalPackages.toString(),
              icon: Icons.widgets_rounded,
              gradient: AppTheme.primaryGradient,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              label: 'Avg. Price',
              value: 'Rs ${avgPrice.toStringAsFixed(0)}',
              icon: Icons.trending_up_rounded,
              gradient: AppTheme.blueGradient,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              label: 'Total Value',
              value: 'Rs ${totalRevenue.toStringAsFixed(0)}',
              icon: Icons.account_balance_wallet_rounded,
              gradient: AppTheme.greenGradient,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required LinearGradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppTheme.radiusMd,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: AppTheme.radiusXxl,
            ),
            child: const Icon(Icons.card_membership_rounded,
                size: 40, color: AppTheme.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'No Packages Available',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first package to get started',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreatePackageDialog,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create Package'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const RoundedRectangleBorder(borderRadius: AppTheme.radiusSm),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PackageProvider>();

    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toolbar: search + create button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Row(
            children: [
              // Search field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: AppTheme.radiusMd,
                    border: Border.all(color: AppTheme.border),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: TextField(
                    controller: _searchController,
                    style:
                        const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search packages…',
                      hintStyle:
                          const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppTheme.primary, size: 20),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 13, horizontal: 16),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  color: AppTheme.textMuted, size: 17),
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
              ),
              const SizedBox(width: 12),

              // Refresh button
              _buildIconBtn(
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh',
                onTap: () => provider.fetchPackages(forceRefresh: true),
              ),
              const SizedBox(width: 8),

              // Create button
              GestureDetector(
                onTap: _showCreatePackageDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: AppTheme.radiusMd,
                    boxShadow: AppTheme.primaryShadow,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'New Package',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Stats row
        _buildStats(context, provider),

        // Package list
        Expanded(
          child: provider.packages.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: () => provider.fetchPackages(forceRefresh: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: provider.packages.length,
                    itemBuilder: (context, index) =>
                        _buildPackageCard(provider.packages[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildIconBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: AppTheme.radiusMd,
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Icon(icon, size: 18, color: AppTheme.primary),
        ),
      ),
    );
  }
}