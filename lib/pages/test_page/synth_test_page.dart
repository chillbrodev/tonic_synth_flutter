import 'package:flutter/material.dart';
import 'fm_drone_page.dart';
import 'xy_speed_page.dart';
import 'delay_test_page.dart';

class SynthTestPage extends StatelessWidget {
  const SynthTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D0D0D),
          elevation: 0,
          title: const Text(
            'TONIC',
            style: TextStyle(
              fontFamily: 'RobotoMono',
              color: Color(0xFF00FF9C),
              fontSize: 14,
              letterSpacing: 6,
              fontWeight: FontWeight.w500,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Color(0xFF00FF9C),
            indicatorWeight: 1.5,
            labelColor: Color(0xFF00FF9C),
            unselectedLabelColor: Color(0xFF555555),
            labelStyle: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 11,
              letterSpacing: 2,
            ),
            tabs: [
              Tab(text: 'FM DRONE'),
              Tab(text: 'XY SPEED'),
              Tab(text: 'DELAY SEQ'),
            ],
          ),
        ),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [FmDronePage(), XySpeedPage(), DelayTestPage()],
        ),
      ),
    );
  }
}
