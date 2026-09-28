import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/payment_accounts.dart';
import '../models/payment_account.dart';
import '../utils/app_colors.dart';

class PaymentSelection {
  final String method; // 'Efectivo' | 'Transferencia'
  final String? accountId;
  final Uint8List? voucherBytes;
  final String? voucherFileName;

  const PaymentSelection({
    required this.method,
    this.accountId,
    this.voucherBytes,
    this.voucherFileName,
  });
}

class PaymentMethodPicker extends StatefulWidget {
  final ValueChanged<PaymentSelection?> onChanged;
  const PaymentMethodPicker({super.key, required this.onChanged});

  @override
  State<PaymentMethodPicker> createState() => _PaymentMethodPickerState();
}

class _PaymentMethodPickerState extends State<PaymentMethodPicker> {
  String? _method;
  PaymentAccount? _account;
  Uint8List? _voucher;
  String? _voucherFileName;

  void _emit() {
    if (_method == 'Efectivo') {
      widget.onChanged(const PaymentSelection(method: 'Efectivo'));
    } else if (_method == 'Transferencia' &&
        _account != null &&
        _voucher != null) {
      widget.onChanged(PaymentSelection(
        method: 'Transferencia',
        accountId: _account!.id,
        voucherBytes: _voucher,
        voucherFileName: _voucherFileName,
      ));
    } else {
      widget.onChanged(null);
    }
  }

  Future<void> _pickVoucher() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _voucher = bytes);
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MÉTODO DE PAGO',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.3,
            color: AppColors.mutedLabel,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MethodCard(
                label: 'Efectivo',
                icon: Icons.payments_outlined,
                selected: _method == 'Efectivo',
                onTap: () {
                  setState(() {
                    _method = 'Efectivo';
                    _account = null;
                    _voucher = null;
                  });
                  _emit();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MethodCard(
                label: 'Transferencia',
                icon: Icons.qr_code_2,
                selected: _method == 'Transferencia',
                onTap: () {
                  setState(() => _method = 'Transferencia');
                  _emit();
                },
              ),
            ),
          ],
        ),
        if (_method == 'Transferencia') ...[
          const SizedBox(height: 16),
          for (final a in paymentAccounts)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AccountOption(
                account: a,
                selected: _account?.id == a.id,
                onTap: () {
                  setState(() => _account = a);
                  _emit();
                },
              ),
            ),
          if (_account != null) ...[
            const SizedBox(height: 6),
            _AccountDetails(account: _account!),
            const SizedBox(height: 16),
            const Text(
              'Comprobante (opcional)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.mutedLabel,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickVoucher,
              child: Container(
                width: double.infinity,
                height: _voucher == null ? 70 : 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.panelBorder),
                ),
                child: _voucher == null
                    ? const Center(
                        child: Text(
                          'Adjuntar comprobante',
                          style: TextStyle(fontSize: 12, color: AppColors.slate),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.memory(_voucher!, fit: BoxFit.cover),
                      ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MethodCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
            color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.panelBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.slate),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountOption extends StatelessWidget {
  final PaymentAccount account;
  final bool selected;
  final VoidCallback onTap;

  const _AccountOption({
    required this.account,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.panelBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(account.icon, size: 20, color: selected ? AppColors.primary : AppColors.slate),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.primary : AppColors.textDark,
                    ),
                  ),
                  Text(account.bank, style: const TextStyle(fontSize: 12, color: AppColors.slate)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: selected ? AppColors.primary : AppColors.panelBorder,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountDetails extends StatelessWidget {
  final PaymentAccount account;
  const _AccountDetails({required this.account});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.dashboardBg,
        border: Border.all(color: AppColors.panelBorder),
      ),
      child: Column(
        children: [
          const Text(
            'ESCANEA PARA PAGAR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.3,
              color: AppColors.mutedLabel,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: 'MODA PLUS|${account.label}|${account.number}',
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _detailRow('Banco / medio', account.bank),
          _detailRow('Titular', account.holder),
          _detailRow(
            account.id == 'nequi' ? 'Número Nequi' : 'Número de cuenta',
            account.number,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.slate)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}