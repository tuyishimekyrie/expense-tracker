import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Expense Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class Expense {
  final String title;
  final double amount;
  final DateTime date;
  final String category;

  Expense({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
  });
}

class SavingsGoal {
  final String title;
  final double targetAmount;
  double currentAmount;
  final DateTime deadline;

  SavingsGoal({
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.deadline,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final List<Expense> _expenses = [];
  final List<SavingsGoal> _savingsGoals = [];
  final double _monthlyBudget = 1000.0;
  
  late TabController _tabController;
  
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Food';

  final List<String> _categories = ['Food', 'Transport', 'Entertainment', 'Education'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _addExpense() {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      return;
    }

    setState(() {
      _expenses.add(
        Expense(
          title: _titleController.text,
          amount: double.parse(_amountController.text),
          date: DateTime.now(),
          category: _selectedCategory,
        ),
      );
    });

    _titleController.clear();
    _amountController.clear();
    Navigator.pop(context);

    _checkBudget();
  }

  void _checkBudget() {
    double totalExpenses = _calculateTotalExpenses();
    if (totalExpenses > _monthlyBudget) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Warning: You have exceeded your monthly budget!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addSavingsGoal() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Savings Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Goal Title'),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Target Amount'),
              keyboardType: TextInputType.number,
            ),
            ListTile(
              title: const Text('Deadline'),
              subtitle: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                setState(() {
                  _savingsGoals.add(
                    SavingsGoal(
                      title: titleController.text,
                      targetAmount: double.parse(amountController.text),
                      deadline: selectedDate,
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _updateSavingsProgress(int index) {
    final amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Progress'),
        content: TextField(
          controller: amountController,
          decoration: const InputDecoration(labelText: 'Amount Saved'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                setState(() {
                  _savingsGoals[index].currentAmount += double.parse(amountController.text);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  double _calculateTotalExpenses() {
    return _expenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  Map<String, double> _calculateCategoryTotals() {
    final Map<String, double> totals = {};
    for (var category in _categories) {
      totals[category] = _expenses
          .where((expense) => expense.category == category)
          .fold(0, (sum, expense) => sum + expense.amount);
    }
    return totals;
  }

  Widget _buildExpensesTab() {
    double totalExpenses = _calculateTotalExpenses();

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Monthly Budget Overview',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: totalExpenses / _monthlyBudget,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    totalExpenses > _monthlyBudget ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Spent: \$${totalExpenses.toStringAsFixed(2)} / \$${_monthlyBudget.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _expenses.length,
            itemBuilder: (ctx, index) {
              final expense = _expenses[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text(expense.category[0])),
                  title: Text(expense.title),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(expense.date)),
                  trailing: Text(
                    '\$${expense.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSavingsTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _savingsGoals.length,
            itemBuilder: (ctx, index) {
              final goal = _savingsGoals[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: goal.currentAmount / goal.targetAmount,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${goal.currentAmount.toStringAsFixed(2)} / \$${goal.targetAmount.toStringAsFixed(2)}',
                          ),
                          Text(
                            'Due: ${DateFormat('MMM dd, yyyy').format(goal.deadline)}',
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => _updateSavingsProgress(index),
                        child: const Text('Update Progress'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Widget _buildReportsTab() {
  //   final categoryTotals = _calculateCategoryTotals();
  //   final double totalSpent = categoryTotals.values.fold(0, (sum, amount) => sum + amount);

  //   return ListView(
  //     padding: const EdgeInsets.all(16),
  //     children: [
  //       const Text(
  //         'Spending by Category',
  //         style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  //       ),
  //       const SizedBox(height: 16),
  //       ...categoryTotals.entries.map((entry) {
  //         final percentage = totalSpent > 0 ? (entry.value / totalSpent) * 100 : 0;
  //         return Column(
  //           children: [
  //             Row(
  //               children: [
  //                 Expanded(
  //                   flex: 3,
  //                   child: Text(entry.key),
  //                 ),
  //                 Expanded(
  //                   flex: 7,
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       LinearProgressIndicator(
  //                         value: percentage / 100,
  //                         backgroundColor: Colors.grey[200],
  //                         valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
  //                       ),
  //                       Text(
  //                         '\$${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
  //                         style: const TextStyle(fontSize: 12),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 16),
  //           ],
  //         );
  //       }).toList(),
  //     ],
  //   );
  // }

Widget _buildReportsTab() {
  final categoryTotals = _calculateCategoryTotals();
  final double totalSpent = categoryTotals.values.fold(0, (sum, amount) => sum + amount);

  List<PieChartSectionData> _getChartSections() {
    return categoryTotals.entries.map((entry) {
      final percentage = totalSpent > 0 ? (entry.value / totalSpent) * 100 : 0;
      return PieChartSectionData(
        value: entry.value,
        title: '${entry.key} \n${percentage.toStringAsFixed(1)}%',
        color: Colors.primaries[categoryTotals.keys.toList().indexOf(entry.key) % Colors.primaries.length],
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  return Column(
    children: [
      const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Spending by Category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      SizedBox(
        height: 250,
        child: PieChart(
          PieChartData(
            sections: _getChartSections(),
            borderData: FlBorderData(show: false),
            centerSpaceRadius: 40,
          ),
        ),
      ),
    ],
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Expense Tracker'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.money_off), text: 'Expenses'),
            Tab(icon: Icon(Icons.savings), text: 'Savings'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExpensesTab(),
          _buildSavingsTab(),
          _buildReportsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddExpenseDialog();
          } else if (_tabController.index == 1) {
            _addSavingsGoal();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            DropdownButton<String>(
              value: _selectedCategory,
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _addExpense,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}