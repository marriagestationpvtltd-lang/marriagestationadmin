import 'dart:typed_data';
import 'package:adminmrz/payment/paymentmodel.dart';
import 'package:adminmrz/payment/paymentprovider.dart';
import 'package:adminmrz/payment/pdfsevice.dart';
import 'package:adminmrz/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_saver/file_saver.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({Key? key}) : super(key: key);

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final TextEditingController _searchController = TextEditingController();
  final PDFService _pdfService = PDFService();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  bool _isExporting = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().fetchPayments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showDateRangePicker() async {
    final provider = context.read<PaymentProvider>();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: provider.startDate != null && provider.endDate != null
          ? DateTimeRange(start: provider.startDate!, end: provider.endDate!)
          : null,
    );

    if (picked != null) {
      provider.setDateRange(picked.start, picked.end);
      provider.fetchFilteredPayments();
    }
  }

  // ── Stats Cards ─────────────────────────────────────────────────────────────

  Widget _buildStatsRow(PaymentSummary? summary) {
    if (summary == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Revenue Overview',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppTheme.greenGradient,
                  borderRadius: AppTheme.radiusSm,
                  boxShadow: AppTheme.primaryShadow,
                ),
                child: Text(
                  summary.totalEarning,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatGradientCard(
                  label: 'Packages Sold',
                  value: summary.totalPackagesSold.toString(),
                  icon: Icons.shopping_bag_rounded,
                  gradient: AppTheme.primaryGradient,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatGradientCard(
                  label: 'Active',
                  value: summary.activePackages.toString(),
                  icon: Icons.check_circle_rounded,
                  gradient: AppTheme.greenGradient,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatGradientCard(
                  label: 'Expired',
                  value: summary.expiredPackages.toString(),
                  icon: Icons.cancel_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF5350), Color(0xFFC62828)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatGradientCard(
                  label: 'Top Method',
                  value: summary.topPaymentMethod,
                  icon: Icons.payment_rounded,
                  gradient: AppTheme.goldGradient,
                  smallValue: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatGradientCard({
    required String label,
    required String value,
    required IconData icon,
    required LinearGradient gradient,
    bool smallValue = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppTheme.radiusMd,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: smallValue ? 11 : 16,
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ───────────────────────────────────────────────────────────────

  Widget _buildSearchBar(PaymentProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: AppTheme.radiusMd,
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.cardShadow,
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search by name, email, package…',
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary, size: 20),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted, size: 18),
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
    );
  }

  // ── Filter Toolbar ───────────────────────────────────────────────────────────

  Widget _buildFilters(BuildContext context) {
    final provider = context.read<PaymentProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: AppTheme.radiusMd,
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            const Icon(Icons.tune_rounded, size: 16, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(
              'Filters',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(width: 12),
            // Date chip
            _buildFilterChip(
              label: provider.startDate != null && provider.endDate != null
                  ? '${_dateFormat.format(provider.startDate!)} – ${_dateFormat.format(provider.endDate!)}'
                  : 'Date Range',
              icon: Icons.calendar_today_rounded,
              onTap: _showDateRangePicker,
              active: provider.startDate != null,
            ),
            const SizedBox(width: 8),
            // Method dropdown
            _buildStyledDropdown<String>(
              value: provider.paymentMethodFilter,
              hint: 'Method',
              icon: Icons.payment_rounded,
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All Methods')),
                ...provider.getPaymentMethods().map(
                      (m) => DropdownMenuItem(value: m, child: Text(m)),
                    ),
              ],
              onChanged: (v) {
                if (v != null) provider.setPaymentMethodFilter(v);
              },
            ),
            const SizedBox(width: 8),
            // Status dropdown
            _buildStyledDropdown<String>(
              value: provider.statusFilter,
              hint: 'Status',
              icon: Icons.flag_rounded,
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All Status')),
                ...provider.getStatusOptions().map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s[0].toUpperCase() + s.substring(1)),
                      ),
                    ),
              ],
              onChanged: (v) {
                if (v != null) provider.setStatusFilter(v);
              },
            ),
            const Spacer(),
            if (provider.paymentMethodFilter != 'all' ||
                provider.statusFilter != 'all' ||
                provider.startDate != null)
              GestureDetector(
                onTap: () {
                  provider.clearFilters();
                  provider.fetchPayments();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.errorLight,
                    borderRadius: AppTheme.radiusSm,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.clear_rounded, size: 13, color: AppTheme.error),
                      const SizedBox(width: 3),
                      Text(
                        'Clear',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary.withOpacity(0.1) : AppTheme.borderLight,
          borderRadius: AppTheme.radiusSm,
          border: Border.all(
            color: active ? AppTheme.primary.withOpacity(0.4) : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: active ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledDropdown<T>({
    required T value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: AppTheme.borderLight,
        borderRadius: AppTheme.radiusSm,
        border: Border.all(color: AppTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          icon: const Icon(Icons.arrow_drop_down, size: 18, color: AppTheme.textSecondary),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          isDense: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ── Export Buttons ───────────────────────────────────────────────────────────

  Widget _buildExportOptions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: AppTheme.radiusMd,
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            const Icon(Icons.download_rounded, size: 16, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(
              'Export Reports',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: AppTheme.textPrimary),
            ),
            const Spacer(),
            _buildExportButton(
              label: 'PDF',
              icon: Icons.picture_as_pdf_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFEF5350), Color(0xFFC62828)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: _isExporting ? null : _generateFullReport,
            ),
            const SizedBox(width: 10),
            _buildExportButton(
              label: 'CSV',
              icon: Icons.table_chart_rounded,
              gradient: AppTheme.greenGradient,
              onTap: _isExporting ? null : _exportToCSV,
            ),
            if (_isExporting) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton({
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: AppTheme.radiusSm,
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Payment Card ─────────────────────────────────────────────────────────────

  Widget _buildPaymentCard(Payment payment) {
    IconData methodIcon;
    switch (payment.paidBy.toLowerCase()) {
      case 'jazzcash':
        methodIcon = Icons.phone_android_rounded;
        break;
      case 'easypaisa':
        methodIcon = Icons.account_balance_wallet_rounded;
        break;
      case 'bank transfer':
      case 'bank':
        methodIcon = Icons.account_balance_rounded;
        break;
      case 'card':
      case 'credit card':
        methodIcon = Icons.credit_card_rounded;
        break;
      default:
        methodIcon = Icons.payment_rounded;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: AppTheme.radiusMd,
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.scaffoldBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: AppTheme.border),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: AppTheme.radiusSm,
                  ),
                  child: Text(
                    '#${payment.id}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.access_time_rounded, size: 12, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  payment.formattedPurchaseDate,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                const Spacer(),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.statusBgColor(payment.packageStatus),
                    borderRadius: AppTheme.radiusSm,
                  ),
                  child: Text(
                    payment.packageStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.statusColor(payment.packageStatus),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Card Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info row
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: AppTheme.radiusMd,
                      ),
                      child: Center(
                        child: Text(
                          payment.fullName.isNotEmpty
                              ? payment.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment.fullName,
                            style: Theme.of(context).textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            payment.email,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Amount badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.successLight,
                        borderRadius: AppTheme.radiusSm,
                        border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                      ),
                      child: Text(
                        payment.packagePrice,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.success,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(color: AppTheme.borderLight, height: 1),
                const SizedBox(height: 12),

                // Package & method details
                Row(
                  children: [
                    const Icon(Icons.card_giftcard_rounded,
                        size: 14, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        payment.packageName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.infoLight,
                        borderRadius: AppTheme.radiusSm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(methodIcon, size: 12, color: AppTheme.info),
                          const SizedBox(width: 4),
                          Text(
                            payment.paidBy,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.info,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.event_rounded,
                        size: 13, color: AppTheme.textMuted),
                    const SizedBox(width: 5),
                    Text(
                      'Expires: ${payment.formattedExpireDate}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.badge_rounded,
                        size: 13, color: AppTheme.textMuted),
                    const SizedBox(width: 5),
                    Text(
                      'UID: ${payment.userId}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildCardActionButton(
                        label: 'Email',
                        icon: Icons.email_outlined,
                        color: AppTheme.info,
                        bgColor: AppTheme.infoLight,
                        onTap: () => _sendEmailToCustomer(payment.email, payment),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildCardActionButton(
                        label: 'Invoice',
                        icon: Icons.receipt_long_rounded,
                        color: AppTheme.success,
                        bgColor: AppTheme.successLight,
                        onTap: () => _generateInvoicePDF(payment),
                      ),
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

  Widget _buildCardActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppTheme.radiusSm,
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
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

  // ── Logic Methods (unchanged) ────────────────────────────────────────────────

  Future<void> _sendEmailToCustomer(String email, Payment payment) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Invoice for ${payment.packageName} - Payment #${payment.id}',
        'body': 'Dear ${payment.fullName},\n\nPlease find attached your invoice for ${payment.packageName} purchased on ${payment.formattedPurchaseDate}.\n\nThank you for your business!\n\nDigital Lami Team',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch email client'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _generateInvoicePDF(Payment payment) async {
    setState(() => _isExporting = true);
    try {
      final Uint8List pdfBytes = await _pdfService.generateInvoicePDF(payment);
      await FileSaver.instance.saveFile(
        name: 'Invoice-${payment.id}-${payment.fullName.replaceAll(' ', '-')}.pdf',
        bytes: pdfBytes,
        mimeType: MimeType.pdf,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice PDF generated successfully'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _generateFullReport() async {
    final provider = context.read<PaymentProvider>();
    setState(() => _isExporting = true);
    try {
      final Uint8List pdfBytes = await _pdfService.generateReportPDF(
        summary: provider.summary!,
        payments: provider.payments,
        title: 'Payment History Report',
        startDate: provider.startDate,
        endDate: provider.endDate,
      );
      await FileSaver.instance.saveFile(
        name: 'Payment-Report-${DateTime.now().millisecondsSinceEpoch}.pdf',
        bytes: pdfBytes,
        mimeType: MimeType.pdf,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Full report PDF generated successfully'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportToCSV() async {
    final provider = context.read<PaymentProvider>();
    setState(() => _isExporting = true);
    try {
      final csvContent = _pdfService.generateCSV(provider.payments);
      final csvBytes = Uint8List.fromList(csvContent.codeUnits);
      await FileSaver.instance.saveFile(
        name: 'Payment-Report-${DateTime.now().millisecondsSinceEpoch}.csv',
        bytes: csvBytes,
        mimeType: MimeType.csv,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV report exported successfully'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting CSV: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();

    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        _buildSearchBar(provider),

        // Stats row
        _buildStatsRow(provider.summary),

        // Filter toolbar
        _buildFilters(context),

        // Export buttons
        _buildExportOptions(),

        // List header
        if (provider.payments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Text(
                  'Payment History',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: AppTheme.radiusSm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.list_alt_rounded, size: 13, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${provider.payments.length} records',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Filtered total
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successLight,
                    borderRadius: AppTheme.radiusSm,
                    border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Rs ${provider.filteredTotalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.success,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Payment list
        Expanded(
          child: RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () => provider.fetchPayments(),
            child: provider.payments.isEmpty
                ? _buildEmptyState(provider)
                : ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24, top: 4),
                    itemCount: provider.payments.length,
                    itemBuilder: (context, index) =>
                        _buildPaymentCard(provider.payments[index]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(PaymentProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: AppTheme.radiusXl,
            ),
            child: const Icon(Icons.payments_outlined, size: 36, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'No payment records found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adjusting your search or filters',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          if (provider.searchQuery.isNotEmpty ||
              provider.paymentMethodFilter != 'all' ||
              provider.statusFilter != 'all') ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                provider.clearFilters();
                provider.fetchPayments();
              },
              icon: const Icon(Icons.clear_all_rounded, size: 16),
              label: const Text('Clear Filters'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            ),
          ],
        ],
      ),
    );
  }
}