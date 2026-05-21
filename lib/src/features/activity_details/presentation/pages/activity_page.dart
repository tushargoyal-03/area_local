import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class ActivityDetailScreen extends StatelessWidget {
  const ActivityDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final items = [
      {
        'icon': IconsaxPlusLinear.calendar,
        'label': 'Today, May 20',
      },
      {
        'icon': IconsaxPlusLinear.clock,
        'label': '6:00 – 8:00 PM',
      },
      {
        'icon': IconsaxPlusLinear.map_1,
        'label': 'JLN Sports, V.N.',
      },
      {
        'icon': IconsaxPlusLinear.user,
        'label': '1 spot left',
      },
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Activity'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(
            top: BorderSide(
              color: Colors.grey.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            _actionButton(
              icon: IconsaxPlusLinear.heart,
              onTap: () {},
            ),
            const SizedBox(width: 12),
            _actionButton(
              icon: IconsaxPlusLinear.share,
              onTap: () {},
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text("I'm Available"),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// User Info
              Row(
                children: [
                  _buildAvatar(
                    'Riya Sharma',
                    size: 48,
                    ring: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Riya Sharma',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '0.4 km away • 12 min ago',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      'Sports',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// Title
              Text(
                'Need a pickleball partner from 6 PM – 8 PM in Vaishali Nagar.',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 10),

              /// Description
              Text(
                'Intermediate level, looking for a chill rally session at JLN Sports Complex. Court is booked, just bring your paddle!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 20),

              /// Info Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.4,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            size: 18,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item['label'] as String,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              /// Map Card
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor.withValues(alpha: 0.25),
                      Colors.purple.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 14,
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              IconsaxPlusLinear.location,
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Open in map',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// Interested Users
              Text(
                '3 people interested',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  _buildAvatar('Karan', size: 36),
                  Transform.translate(
                    offset: const Offset(-10, 0),
                    child: _buildAvatar('Meera', size: 36),
                  ),
                  Transform.translate(
                    offset: const Offset(-20, 0),
                    child: _buildAvatar('Dev', size: 36),
                  ),
                  Transform.translate(
                    offset: const Offset(-30, 0),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '+5',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon),
      ),
    );
  }

  Widget _buildAvatar(
    String name, {
    double size = 40,
    bool ring = false,
  }) {
    return Container(
      padding: ring ? const EdgeInsets.all(2) : EdgeInsets.zero,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: ring
            ? Border.all(
                color: Colors.blue,
                width: 2,
              )
            : null,
      ),
      child: CircleAvatar(
        radius: size / 2,
        child: Text(
          name.substring(0, 1),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
