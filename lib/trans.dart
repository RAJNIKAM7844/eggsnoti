import 'package:flutter/material.dart';

class TransactionPage extends StatelessWidget {
  const TransactionPage({super.key});

  final List<Map<String, dynamic>> transactions = const [
    {
      'date': '2025-04-20 14:30',
      'description': 'Egg Purchase - Batch #123',
      'amount': 1500.00,
      'status': 'Completed',
    },
    {
      'date': '2025-04-18 09:15',
      'description': 'Egg Purchase - Batch #122',
      'amount': 1200.50,
      'status': 'Pending',
    },
    {
      'date': '2025-04-15 16:45',
      'description': 'Egg Purchase - Batch #121',
      'amount': 1800.75,
      'status': 'Completed',
    },
    {
      'date': '2025-04-10 11:20',
      'description': 'Egg Purchase - Batch #120',
      'amount': 900.25,
      'status': 'Failed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(size.width * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Your Transactions',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
              ),
              SizedBox(height: size.height * 0.02),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return Card(
                    child: ListTile(
                      contentPadding: EdgeInsets.all(size.width * 0.04),
                      title: Text(
                        transaction['description'],
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: size.height * 0.005),
                          Text(
                            'Date: ${transaction['date']}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            'Amount: ₹${transaction['amount'].toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      trailing: Text(
                        transaction['status'],
                        style: TextStyle(
                          color: transaction['status'] == 'Completed'
                              ? const Color(0xFF388E3C)
                              : transaction['status'] == 'Pending'
                                  ? const Color(0xFFFFD54F)
                                  : const Color(0xFFD32F2F),
                          fontWeight: FontWeight.bold,
                          fontSize: size.width * 0.035,
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: size.height * 0.04),
            ],
          ),
        ),
      ),
    );
  }
}
