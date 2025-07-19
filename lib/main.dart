// DEPENDENCIES: fl_chart: ^0.68.0
// DEPENDENCIES: math_expressions: ^2.4.0
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:math_expressions/math_expressions.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Graph Plotter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _equationController = TextEditingController();
  List<FlSpot> _data = [];

  void _plotGraph() {
    String equation = _equationController.text;
    ContextModel cm = ContextModel();
    Variable x = Variable('x');
    Expression exp = Parser().parse(equation);
    setState(() {
      _data = [];
      for (double i = -10; i <= 10; i += 0.1) {
        cm.bindVariable(x, Number(i));
        double y = exp.evaluate(EvaluationType.REAL, cm);
        _data.add(FlSpot(i, y));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Graph Plotter'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _equationController,
              decoration: InputDecoration(labelText: 'Enter Equation (e.g., sin(x), x*x)'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _plotGraph,
              child: Text('Plot Graph'),
            ),
            SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: _data,
                      isCurved: true,
                    ),
                  ],
                  titlesData: FlTitlesData(
                    show: true,
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}