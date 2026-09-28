import 'package:flutter/material.dart';

import '../models/payment_account.dart';

const List<PaymentAccount> paymentAccounts = [
  PaymentAccount(
    id: 'nequi',
    label: 'Nequi',
    bank: 'Billetera digital',
    holder: 'Moda Plus',
    number: '300 000 0000',
    icon: Icons.phone_android,
  ),
  PaymentAccount(
    id: 'bancolombia',
    label: 'Cuenta de ahorros',
    bank: 'Bancolombia',
    holder: 'Moda Plus',
    number: '000 000 00000',
    icon: Icons.account_balance,
  ),
];