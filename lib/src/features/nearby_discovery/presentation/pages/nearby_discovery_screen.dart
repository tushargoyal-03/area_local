import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class NearbyDiscoveryScreen extends StatelessWidget {
  const NearbyDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final people = ['Riya Sharma', 'Karan Singh', 'Meera Patel', 'Dev Arora'];
    final interests = ['pickleball', 'gym buddy', 'yoga', 'cycling'];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nearby'),
            SizedBox(height: 2),
            Text(
              'Vaishali Nagar · 2 km radius',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(IconsaxPlusLinear.filter),
          )
        ],
      ),
      body: Column(
        children: [
          /// Chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: const [
                _ChipItem('People', true),
                _ChipItem('Activities', false),
                _ChipItem('Business', false),
                _ChipItem('Events', false),
                _ChipItem('Society', false),
              ],
            ),
          ),

          /// Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              children: [
                /// Map / Discovery Card
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withValues(alpha: 0.2),
                        Colors.purple.withValues(alpha: 0.15),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      /// Fake people pins
                      ...[
                        {'left': 0.34, 'top': 0.22, 'name': 'Riya'},
                        {'left': 0.60, 'top': 0.45, 'name': 'K'},
                        {'left': 0.25, 'top': 0.60, 'name': 'M'},
                        {'left': 0.75, 'top': 0.70, 'name': 'D'},
                      ].map(
                        (p) => Positioned(
                          left: MediaQuery.of(context).size.width *
                              (p['left'] as double) *
                              0.85,
                          top: 160 * (p['top'] as double),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 8,
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    (p['name'] as String)[0],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      /// Center Button
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(
                            IconsaxPlusLinear.location,
                            size: 14,
                          ),
                          label: const Text(
                            'Center on me',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                /// Active count
                const Row(
                  children: [
                    Icon(IconsaxPlusLinear.trend_up,
                        size: 16, color: Colors.blue),
                    SizedBox(width: 6),
                    Text(
                      '14 active nearby right now',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                /// People List
                ...List.generate(people.length, (i) {
                  return _NearbyCard(
                    name: people[i],
                    index: i,
                    interest: interests[i],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================
/// NEARBY CARD
/// ===============================
class _NearbyCard extends StatelessWidget {
  final String name;
  final int index;
  final String interest;

  const _NearbyCard({
    required this.name,
    required this.index,
    required this.interest,
  });

  @override
  Widget build(BuildContext context) {
    final distance = (0.2 + index * 0.3).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                child: Text(name[0]),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(IconsaxPlusLinear.map, size: 12),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '$distance km · Looking for $interest',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Say hi',
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================
/// CHIP
/// ===============================
class _ChipItem extends StatelessWidget {
  final String label;
  final bool active;

  const _ChipItem(this.label, this.active);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: active
            ? Colors.blue.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
