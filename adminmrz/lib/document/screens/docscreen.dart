import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adminmrz/theme/app_theme.dart';
import '../docprovider/docmodel.dart';
import '../docprovider/docservice.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _rejectReasonController = TextEditingController();
  String? _selectedImageUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDocuments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rejectReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    final provider = Provider.of<DocumentsProvider>(context, listen: false);
    await provider.fetchDocuments();
  }

  // ================= APPROVE DOCUMENT =================
  Future<void> _approveDocument(Document document) async {
    final provider = Provider.of<DocumentsProvider>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.successLight,
                borderRadius: AppTheme.radiusSm,
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: AppTheme.success, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Approve Document',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
          ],
        ),
        content: Text(
          'Are you sure you want to approve ${document.fullName}\'s document?',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusSm),
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await provider.updateDocumentStatus(
          userId: document.userId,
          action: 'approve',
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Document approved for ${document.fullName}'),
              backgroundColor: AppTheme.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to approve: ${provider.error}'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  // ================= REJECT DOCUMENT =================
  Future<void> _rejectDocument(Document document) async {
    _rejectReasonController.clear();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorLight,
                borderRadius: AppTheme.radiusSm,
              ),
              child: const Icon(Icons.cancel_outlined,
                  color: AppTheme.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Reject Document',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Document for ${document.fullName}',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please provide a reason for rejection:',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _rejectReasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_rejectReasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a rejection reason'),
                    backgroundColor: AppTheme.error,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await _performReject(document);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusSm),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _performReject(Document document) async {
    final provider = Provider.of<DocumentsProvider>(context, listen: false);

    try {
      final success = await provider.updateDocumentStatus(
        userId: document.userId,
        action: 'reject',
        rejectReason: _rejectReasonController.text.trim(),
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document rejected for ${document.fullName}'),
            backgroundColor: AppTheme.warning,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject: ${provider.error}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  // ================= IMAGE PREVIEW =================
  void _showImagePreview(String imageUrl) {
    setState(() {
      _selectedImageUrl = imageUrl;
    });

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: AppTheme.radiusMd,
                boxShadow: AppTheme.elevatedShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 3,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: AppTheme.primary,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.borderLight,
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image,
                                        size: 48, color: AppTheme.textMuted),
                                    SizedBox(height: 8),
                                    Text('Failed to load image',
                                        style: TextStyle(
                                            color: AppTheme.textMuted)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 20),
                        label: const Text('Close'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: AppTheme.radiusSm),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      setState(() {
        _selectedImageUrl = null;
      });
    });
  }

  // ================= DOCUMENT CARD =================
  Widget _buildDocumentCard(Document document, String currentTab) {
    final statusColor = _getStatusColor(document.status);
    final statusBg = _getStatusBgColor(document.status);
    final isPending = currentTab == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: AppTheme.radiusMd,
        boxShadow: AppTheme.cardShadow,
        border: Border(
          left: BorderSide(color: statusColor, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Pending header highlight ──────────────────────────────────────
          if (isPending)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: AppTheme.warningLight,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded,
                      size: 14, color: AppTheme.warning),
                  const SizedBox(width: 6),
                  Text(
                    'Awaiting Review',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.warning,
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Document image thumbnail ──────────────────────────────
                GestureDetector(
                  onTap: () => _showImagePreview(document.fullPhotoUrl),
                  child: Stack(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          borderRadius: AppTheme.radiusSm,
                          color: AppTheme.borderLight,
                        ),
                        child: ClipRRect(
                          borderRadius: AppTheme.radiusSm,
                          child: Image.network(
                            document.fullPhotoUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, _, __) => const Center(
                              child: Icon(Icons.broken_image,
                                  size: 28, color: AppTheme.textMuted),
                            ),
                          ),
                        ),
                      ),
                      // Zoom icon overlay
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.zoom_in,
                              color: Colors.white, size: 13),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // ── User info & details ───────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                document.firstName.isNotEmpty
                                    ? document.firstName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Name + email
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  document.fullName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  document.email,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: AppTheme.radiusSm,
                            ),
                            child: Text(
                              document.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ── Info grid ────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.scaffoldBg,
                          borderRadius: AppTheme.radiusSm,
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _infoCell(
                                    icon: Icons.badge_outlined,
                                    iconColor: AppTheme.primary,
                                    label: 'Doc Type',
                                    value: document.documentType,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _infoCell(
                                    icon: Icons.numbers_outlined,
                                    iconColor: AppTheme.success,
                                    label: 'Doc ID',
                                    value: document.documentIdNumber,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _infoCell(
                                    icon: Icons.person_outline,
                                    iconColor: AppTheme.primaryDark,
                                    label: 'Gender',
                                    value: document.gender,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _infoCell(
                                    icon: Icons.perm_identity_outlined,
                                    iconColor: AppTheme.accent,
                                    label: 'User ID',
                                    value: '#${document.userId}',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Verification badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: document.isVerified == 1
                              ? AppTheme.successLight
                              : AppTheme.warningLight,
                          borderRadius: AppTheme.radiusSm,
                          border: Border.all(
                            color: document.isVerified == 1
                                ? AppTheme.success.withOpacity(0.3)
                                : AppTheme.warning.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              document.isVerified == 1
                                  ? Icons.verified_outlined
                                  : Icons.pending_outlined,
                              size: 13,
                              color: document.isVerified == 1
                                  ? AppTheme.success
                                  : AppTheme.warning,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              document.isVerified == 1
                                  ? 'Verified User'
                                  : 'Not Verified',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: document.isVerified == 1
                                    ? AppTheme.success
                                    : AppTheme.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Action buttons (pending only) ─────────────────────────────
          if (isPending) ...[
            Container(
              height: 1,
              color: AppTheme.borderLight,
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            Consumer<DocumentsProvider>(
              builder: (context, provider, child) {
                if (provider.isActionLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.primary),
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      // Reject
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _rejectDocument(document),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(color: AppTheme.error),
                            padding:
                                const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                                borderRadius: AppTheme.radiusSm),
                            textStyle: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Approve
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approveDocument(document),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                                borderRadius: AppTheme.radiusSm),
                            textStyle: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoCell({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.error;
      case 'pending':
        return AppTheme.warning;
      default:
        return AppTheme.textSecondary;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppTheme.successLight;
      case 'rejected':
        return AppTheme.errorLight;
      case 'pending':
        return AppTheme.warningLight;
      default:
        return AppTheme.borderLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DocumentsProvider>(context);

    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 16),
            Text('Loading documents…',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.errorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline,
                    size: 40, color: AppTheme.error),
              ),
              const SizedBox(height: 16),
              Text(
                provider.error!,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadDocuments,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.radiusSm),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // ── Tab bar ───────────────────────────────────────────────────────
        Container(
          color: AppTheme.cardBg,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primary,
            indicatorWeight: 3,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            labelStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500),
            tabs: [
              _tabItem('Pending',
                  provider.pendingDocuments.length, AppTheme.warning),
              _tabItem('Approved',
                  provider.approvedDocuments.length, AppTheme.success),
              _tabItem('Rejected',
                  provider.rejectedDocuments.length, AppTheme.error),
            ],
          ),
        ),

        // ── Tab content ───────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _list(provider.pendingDocuments, 'pending'),
              _list(provider.approvedDocuments, 'approved'),
              _list(provider.rejectedDocuments, 'rejected'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabItem(String label, int count, Color countColor) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: countColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: countColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _list(List<Document> docs, String tabName) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.folder_open_outlined,
                  size: 40, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            const Text(
              'No documents found',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Documents will appear here once submitted.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _loadDocuments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: docs.length,
        itemBuilder: (_, i) => _buildDocumentCard(docs[i], tabName),
      ),
    );
  }
}