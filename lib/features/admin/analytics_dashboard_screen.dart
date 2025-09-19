import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  String _selectedPeriod = "Monthly";
  final List<String> _periodOptions = ["Daily", "Weekly", "Monthly", "Custom"];
  DateTimeRange? _dateRange;

  Future<Map<String, dynamic>> fetchAnalytics() async {
    try {
      Query query = FirebaseFirestore.instance.collection('bookings');
      if (_dateRange != null) {
        query = query
            .where('checkIn', isGreaterThanOrEqualTo: _dateRange!.start.toIso8601String())
            .where('checkOut', isLessThanOrEqualTo: _dateRange!.end.toIso8601String());
      }
      final bookingsSnapshot = await query.get();
      final reviewsSnapshot = await FirebaseFirestore.instance.collection('reviews').get();

      double totalRevenue = 0;
      final Set<String> uniqueUsers = <String>{};
      int totalNights = 0;
      int totalRooms = 50; // Fetch from hotels collection if needed

      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if ((data['status'] ?? '') == 'confirmed') {
          totalRevenue += (data['totalPrice'] as num?)?.toDouble() ?? 0;
          uniqueUsers.add(data['userId'] as String);
          try {
            final checkIn = DateTime.parse(data['checkIn']);
            final checkOut = DateTime.parse(data['checkOut']);
            final nights = checkOut.difference(checkIn).inDays;
            totalNights += nights;
          } catch (e) {
            // Skip invalid dates
          }
        }
      }

      double avgRating = 0;
      if (reviewsSnapshot.docs.isNotEmpty) {
        final sumRatings = reviewsSnapshot.docs.fold<double>(
          0.0,
          (sum, r) => sum + ((r['rating'] ?? 0) as num).toDouble(),
        );
        avgRating = sumRatings / reviewsSnapshot.docs.length;
      }

      final daysInPeriod = _dateRange?.duration.inDays ?? 30;
      double occupancyRate = (totalNights / (totalRooms * daysInPeriod)) * 100;
      double revPar = totalRevenue / totalRooms;
      double adr = totalNights > 0 ? totalRevenue / totalNights : 0;

      return {
        'totalBookings': bookingsSnapshot.size,
        'uniqueUsers': uniqueUsers.length,
        'totalRevenue': totalRevenue,
        'averageRating': avgRating,
        'totalReviews': reviewsSnapshot.size,
        'occupancyRate': occupancyRate.clamp(0, 100),
        'revPar': revPar,
        'adr': adr,
      };
    } catch (e) {
      print('Analytics error: $e');
      return {}; // Empty on error
    }
  }

  @override
  Widget build(BuildContext context) {
    // Role-based check
    final authProvider = Provider.of<AuthProvider>(context);
    if (!authProvider.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Analytics Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: _dateRange,
              );
              if (picked != null) setState(() => _dateRange = picked);
            },
          ),
          DropdownButton<String>(
            value: _selectedPeriod,
            items: _periodOptions.map((period) => DropdownMenuItem<String>(value: period, child: Text(period))).toList(),
            onChanged: (value) => setState(() => _selectedPeriod = value ?? 'Monthly'),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchAnalytics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available'));
          }
          final data = snapshot.data!;

          return LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: EdgeInsets.all(constraints.maxWidth > 600 ? 24 : 16),
              child: Column(
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: constraints.maxWidth > 600 ? 4 : 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildMetricCard("Total Revenue", "\$${data['totalRevenue'].toStringAsFixed(2)}", Icons.attach_money),
                      _buildMetricCard("Total Bookings", "${data['totalBookings']}", Icons.book_online),
                      _buildMetricCard("Unique Users", "${data['uniqueUsers']}", Icons.people),
                      _buildMetricCard("Avg Rating", "${data['averageRating'].toStringAsFixed(1)}", Icons.star),
                      _buildMetricCard("Occupancy Rate", "${data['occupancyRate'].toStringAsFixed(1)}%", Icons.hotel),
                      _buildMetricCard("RevPAR", "\$${data['revPar'].toStringAsFixed(2)}", Icons.trending_up),
                      _buildMetricCard("ADR", "\$${data['adr'].toStringAsFixed(2)}", Icons.trending_up),
                      _buildMetricCard("Total Reviews", "${data['totalReviews']}", Icons.rate_review),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    child: _buildTrendChart(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.blue),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    final List<FlSpot> spots = List.generate(
      12,
      (index) => FlSpot(index.toDouble(), (1000 + Random().nextInt(4000)).toDouble()),
    );

    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                child: Text("\$${value.toInt()}"),
                meta: meta,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                child: Text("M${value.toInt() + 1}"),
                meta: meta,
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}