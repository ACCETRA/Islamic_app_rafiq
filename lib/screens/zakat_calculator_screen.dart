import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../widgets/feature_header.dart';
import '../widgets/metric_card.dart';

// ==================== ZAKAT CALCULATOR ====================
class ZakatCalculatorScreen extends StatefulWidget {
  const ZakatCalculatorScreen({super.key});

  @override
  State<ZakatCalculatorScreen> createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends State<ZakatCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cashController = TextEditingController();
  final _goldController = TextEditingController();
  final _silverController = TextEditingController();
  final _investmentsController = TextEditingController();
  final _debtsController = TextEditingController();
  double _zakatAmount = 0;
  bool _showResult = false;

  @override
  void dispose() {
    _cashController.dispose();
    _goldController.dispose();
    _silverController.dispose();
    _investmentsController.dispose();
    _debtsController.dispose();
    super.dispose();
  }

  void _calculateZakat() {
    if (_formKey.currentState!.validate()) {
      final cash = double.tryParse(_cashController.text) ?? 0;
      final gold = double.tryParse(_goldController.text) ?? 0;
      final silver = double.tryParse(_silverController.text) ?? 0;
      final investments = double.tryParse(_investmentsController.text) ?? 0;
      final debts = double.tryParse(_debtsController.text) ?? 0;

      final totalWealth = cash + gold + silver + investments - debts;
      final nisab = 85 * 60;
      double zakat = 0;

      if (totalWealth >= nisab) {
        zakat = totalWealth * 0.025;
      }

      setState(() {
        _zakatAmount = zakat;
        _showResult = true;
      });

      DatabaseHelper.instance
          .saveZakatRecord(DateTime.now().year, totalWealth, zakat);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Zakat Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FeatureHeader(
                icon: Icons.calculate_rounded,
                title: 'Zakat Calculator',
                subtitle: '2.5% of qualifying wealth above nisab',
              ),
              const SizedBox(height: 20),
              Text('Enter your assets and liabilities', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cashController,
                decoration: const InputDecoration(labelText: 'Cash in hand & bank (\$)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _goldController,
                decoration: const InputDecoration(labelText: 'Value of gold (\$)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _silverController,
                decoration: const InputDecoration(labelText: 'Value of silver (\$)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _investmentsController,
                decoration: const InputDecoration(labelText: 'Investments & stocks (\$)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _debtsController,
                decoration: const InputDecoration(labelText: 'Debts owed (\$)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _calculateZakat,
                icon: const Icon(Icons.calculate_rounded),
                label: const Text('Calculate Zakat'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              if (_showResult) ...[
                const SizedBox(height: 24),
                MetricCard(
                  label: '2.5% of your qualifying wealth',
                  value: '\$${_zakatAmount.toStringAsFixed(2)}',
                  icon: Icons.volunteer_activism_rounded,
                  highlighted: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
