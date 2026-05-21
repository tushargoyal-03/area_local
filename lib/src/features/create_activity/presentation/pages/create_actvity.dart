import 'package:area_connect/src/imports/imports.dart';

/// ===============================
/// CREATE ACTIVITY SCREEN
/// ===============================

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({super.key});

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final List<String> categories = [
    'Sports',
    'Fitness',
    'Hobbies',
    'Help',
    'Events',
    'Wellness',
    'Food',
  ];

  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leadingWidth: 60,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New activity'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              'Post',
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text('Post activity'),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Categories
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    categories.length,
                    (index) {
                      final selected = selectedIndex == index;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(categories[index]),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// Title
              _sectionLabel('Title'),

              const SizedBox(height: 8),

              Text(
                'Need a pickleball partner|',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                '28 / 80',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 24),

              /// Description
              _sectionLabel('Description'),

              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  minHeight: 100,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  'Intermediate level, chill rally session...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13.5,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Form Rows
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.7,
                children: const [
                  FormRow(
                    icon: IconsaxPlusLinear.calendar,
                    label: 'Today, May 20',
                  ),
                  FormRow(
                    icon: IconsaxPlusLinear.clock,
                    label: '6:00 – 8:00 PM',
                  ),
                  FormRow(
                    icon: IconsaxPlusLinear.map,
                    label: 'JLN Sports, V.N.',
                  ),
                  FormRow(
                    icon: IconsaxPlusLinear.user,
                    label: '2 people',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// Photo Upload
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.4),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      IconsaxPlusLinear.camera,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a photo (optional)',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade600,
      ),
    );
  }
}

/// ===============================
/// FORM ROW
/// ===============================

class FormRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const FormRow({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 18,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================
/// ACTIVITY CARD
/// ===============================

class ActivityCard extends StatelessWidget {
  final bool compact;
  final String who;
  final String title;
  final String tag;
  final String availability;
  final int interested;

  const ActivityCard({
    super.key,
    this.compact = false,
    this.who = 'Riya Sharma',
    this.title = 'Need a pickleball partner from 6PM – 8PM in Vaishali Nagar',
    this.tag = 'Sports',
    this.availability = 'Today • 6:00 – 8:00 PM',
    this.interested = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: Colors.black.withValues(alpha: 0.03),
          ),
        ],
      ),
      child: Column(
        children: [
          /// Top Row
          Row(
            children: [
              _avatar(who),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      who,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          IconsaxPlusLinear.map,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '0.4 km · 12 min',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(tag),
              ),
            ],
          ),

          const SizedBox(height: 14),

          /// Title
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),

          if (!compact) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _miniChip(
                  icon: IconsaxPlusLinear.clock,
                  text: availability,
                ),
                _miniChip(
                  icon: IconsaxPlusLinear.map,
                  text: 'Vaishali Nagar',
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),

          Divider(
            color: Colors.grey.withValues(alpha: 0.15),
            height: 1,
          ),

          const SizedBox(height: 14),

          /// Bottom Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _metaItem(
                    IconsaxPlusLinear.user,
                    interested.toString(),
                  ),
                  const SizedBox(width: 14),
                  _metaItem(
                    IconsaxPlusLinear.heart,
                    '24',
                  ),
                  const SizedBox(width: 14),
                  Icon(
                    IconsaxPlusLinear.bookmark,
                    size: 16,
                    color: Colors.grey.shade700,
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "I'm Available",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar(String name) {
    return CircleAvatar(
      radius: 20,
      child: Text(
        name[0],
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _miniChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaItem(
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Icon(icon, size: 15),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
