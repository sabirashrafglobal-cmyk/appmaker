import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const ReliabilityKPIApp());
}

class ReliabilityKPIApp extends StatelessWidget {
  const ReliabilityKPIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const Dashboard(),
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final Random _rand = Random();

  // Time
  double operatingTime = 0; // hours

  // Sensors
  double temperature = 0;
  double vibration = 0;
  double pressure = 0;

  // Reliability parameters
  final double beta = 2.6;
  final double eta = 550;

  // Maintenance parameters
  final double mttr = 8; // Mean Time To Repair (hours)

  String status = "INITIALIZING";

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 2), (_) {
      setState(() {
        operatingTime += 5;

        temperature = 60 + _rand.nextDouble() * 60;
        vibration = _rand.nextDouble() * 12;
        pressure = 90 + _rand.nextDouble() * 40;

        status = evaluateCondition();
      });
    });
  }

  // ================= Reliability Models =================

  double reliability(double t) =>
      exp(-pow(t / eta, beta));

  double failureRate(double t) =>
      (beta / eta) * pow(t / eta, beta - 1);

  double mttf() =>
      eta * gamma(1 + 1 / beta);

  double mtbf() => mttf();

  double availability() =>
      mtbf() / (mtbf() + mttr);

  double rul() {
    final value = mttf() - operatingTime;
    return value > 0 ? value : 0;
  }

  // ================= KPI Calculations =================

  double healthIndex() {
    double score = 100;

    score -= (temperature - 60) * 0.4;
    score -= vibration * 3;
    score -= (pressure - 90) * 0.2;
    score -= operatingTime / 20;

    return score.clamp(0, 100);
  }

  String riskLevel() {
    final h = healthIndex();
    if (h < 30) return "HIGH";
    if (h < 60) return "MEDIUM";
    return "LOW";
  }

  // ================= Utilities =================

  double gamma(double z) {
    if (z == 1) return 1;
    if (z == 0.5) return sqrt(pi);
    return (z - 1) * gamma(z - 1);
  }

  String evaluateCondition() {
    if (temperature > 100 || vibration > 10 || pressure > 120) {
      return "CRITICAL";
    }
    if (temperature > 85 || vibration > 7 || pressure > 110) {
      return "WARNING";
    }
    return "NORMAL";
  }

  Color statusColor() {
    switch (status) {
      case "NORMAL":
        return Colors.green;
      case "WARNING":
        return Colors.orange;
      case "CRITICAL":
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  Widget kpiTile(String label, String value) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = reliability(operatingTime) * 100;
    final a = availability() * 100;

    return Scaffold(
      appBar: AppBar(title: const Text("Industrial Reliability KPI Dashboard")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: statusColor(),
              child: Text(
                "SYSTEM STATUS: $status",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
              ),
            ),

            const SizedBox(height: 16),

            // Sensors
            kpiTile("Operating Time", "${operatingTime.toStringAsFixed(0)} h"),
            kpiTile("Temperature", "${temperature.toStringAsFixed(1)} °C"),
            kpiTile("Vibration", "${vibration.toStringAsFixed(2)} mm/s"),
            kpiTile("Pressure", "${pressure.toStringAsFixed(1)} bar"),

            const Divider(),

            // Reliability KPIs
            kpiTile("Reliability", "${r.toStringAsFixed(2)} %"),
            kpiTile("Availability", "${a.toStringAsFixed(2)} %"),
            kpiTile("MTBF", "${mtbf().toStringAsFixed(1)} h"),
            kpiTile("MTTR", "$mttr h"),
            kpiTile("Failure Rate", failureRate(operatingTime).toStringAsFixed(6)),
            kpiTile("RUL", "${rul().toStringAsFixed(1)} h"),

            const Divider(),

            // Health KPIs
            kpiTile("Health Index", healthIndex().toStringAsFixed(1)),
            kpiTile("Risk Level", riskLevel()),
          ],
        ),
      ),
    );
  }
}
