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
      title: 'Equation Grapher',
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
    ContextModel contextModel = ContextModel();
    var expression = Parser().parse(equation);
    _data = [];
    for (double x = -10; x <= 10; x += 0.1) {
      contextModel.bindVariable(Variable('x'), Number(x));
      double y = expression.evaluate(EvaluationType.REAL, contextModel);
      _data.add(FlSpot(x, y));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Equation Grapher'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _equationController,
              decoration: InputDecoration(hintText: 'Enter equation (e.g., sin(x), x*x)'),
            ),
            ElevatedButton(
              onPressed: _plotGraph,
              child: Text('Plot Graph'),
            ),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: SideTitles(
                      showTitles: true,
                      getTitles: (value) => value.toInt().toString(),
                    ),
                    leftTitles: SideTitles(
                      showTitles: true,
                      getTitles: (value) => value.toInt().toString(),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _data,
                      isCurved: true,
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
}