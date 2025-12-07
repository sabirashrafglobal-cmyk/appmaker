import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: TankHeatMap());
  }
}

class TankHeatMap extends StatefulWidget {
  @override
  _TankHeatMapState createState() => _TankHeatMapState();
}

class _TankHeatMapState extends State<TankHeatMap> {
  List<List<double>> tempData = [];
  TextEditingController rowsController = TextEditingController(text: '10');
  TextEditingController colsController = TextEditingController(text: '10');
  TextEditingController tempMinController = TextEditingController(text: '20');
  TextEditingController tempMaxController = TextEditingController(text: '100');

  Future<void> fetchTemperature() async {
    final rows = rowsController.text;
    final cols = colsController.text;
    final tempMin = tempMinController.text;
    final tempMax = tempMaxController.text;

    final url =
        'http://10.0.2.2:5000/tank_temperature?rows=$rows&cols=$cols&temp_min=$tempMin&temp_max=$tempMax';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      setState(() {
        tempData = data.map((row) => row.map((e) => e.toDouble()).toList()).toList();
      });
    } else {
      print('Failed to fetch data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Overhead Tank Heatmap')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User input section
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: TextField(controller: rowsController, decoration: InputDecoration(labelText: 'Rows'))),
                      SizedBox(width: 10),
                      Expanded(child: TextField(controller: colsController, decoration: InputDecoration(labelText: 'Columns'))),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: tempMinController, decoration: InputDecoration(labelText: 'Min Temp'))),
                      SizedBox(width: 10),
                      Expanded(child: TextField(controller: tempMaxController, decoration: InputDecoration(labelText: 'Max Temp'))),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: fetchTemperature,
                    child: Text('Generate Heatmap'),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Heatmap display
            tempData.isEmpty
                ? CircularProgressIndicator()
                : Container(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      children: tempData.map((row) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: row.map((temp) {
                            return Container(
                              width: 20,
                              height: 20,
                              margin: EdgeInsets.all(1),
                              color: getColor(temp),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Color getColor(double temp) {
    double t = (temp - double.parse(tempMinController.text)) /
        (double.parse(tempMaxController.text) - double.parse(tempMinController.text));
    int r = (255 * t).toInt();
    int b = (255 * (1 - t)).toInt();
    return Color.fromARGB(255, r, 0, b);
  }
}
