import 'package:flutter/material.dart';

class PaymentAccount {
  final String id;
  final String label;
  final String bank;
  final String holder;
  final String number;
  final IconData icon;

  const PaymentAccount({
    required this.id,
    required this.label,
    required this.bank,
    required this.holder,
    required this.number,
    required this.icon,
  });
}