import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/bloc/auth_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavigationIndex = 0;
  String _selectedFilter = "All";

  // Mock Developer Listings Data
  final List<Map<String, dynamic>> _mockListings = [
    {
      "name": "Sarah Chen",
      "role": "Flutter & Mobile Architect",
      "experience": "5 yrs",
      "skills": ["Flutter", "Dart", "Firebase"],
      "status": "Available",
      "color": Colors.cyanAccent,
    },
    {
      "name": "Alex Mercer",
      "role": "Node Backend Engineer",
      "experience": "7 yrs",
      "skills": ["Node.js", "Express", "PostgreSQL", "REST API"],
      "status": "Busy",
      "color": Colors.orangeAccent,
    },
    {
      "name": "Elena Rostova",
      "role": "Fullstack Cloud Developer",
      "experience": "4 yrs",
      "skills": ["React", "TypeScript", "Node.js", "AWS"],
      "status": "Available",
      "color": Colors.tealAccent,
    },
    {
      "name": "Marcus Vance",
      "role": "DevOps & Security Specialist",
      "experience": "8 yrs",
      "skills": ["Docker", "Kubernetes", "CI/CD", "Linux"],
      "status": "Available",
      "color": Colors.purpleAccent,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    String userEmail = 'developer@propkart.com';

    if (state is Authenticated) {
      userEmail = state.user.email;
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigoAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.blur_on_rounded, color: Colors.indigoAccent, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'PropKart',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1C1A18), // Slate 900
        elevation: 0,
        actions: [
          // Sign Out button
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Sign Out',
            onPressed: () {
              context.read<AuthBloc>().add(LogoutRequested());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1C1A18), // Slate 900
              Color(0xFF1E1B4B), // Indigo 950
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Welcome Row
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(fontSize: 14, color: Colors.indigo.shade200),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar & Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                children: [
                  // M3 Search Bar
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search listings...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.indigoAccent),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.indigoAccent, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ["All", "Flutter", "Node.js", "PostgreSQL"].map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(filter),
                            selected: isSelected,
                            selectedColor: Colors.indigoAccent.withOpacity(0.25),
                            checkmarkColor: Colors.indigoAccent,
                            backgroundColor: Colors.white.withOpacity(0.04),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: isSelected ? Colors.indigoAccent : Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Listings Header
            const Padding(
              padding: EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 8.0),
              child: Text(
                'Featured Developers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Active Listings View
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: _mockListings.length,
                itemBuilder: (context, index) {
                  final dev = _mockListings[index];

                  // Local filter logic
                  if (_selectedFilter != "All" &&
                      !dev['skills'].contains(_selectedFilter)) {
                    return const SizedBox.shrink();
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color: Colors.white.withOpacity(0.04),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dev['name'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dev['role'],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: dev['status'] == 'Available'
                                      ? Colors.teal.withOpacity(0.15)
                                      : Colors.orange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: dev['status'] == 'Available'
                                        ? Colors.tealAccent.withOpacity(0.4)
                                        : Colors.orangeAccent.withOpacity(0.4),
                                  ),
                                ),
                                child: Text(
                                  dev['status'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: dev['status'] == 'Available'
                                        ? Colors.tealAccent
                                        : Colors.orangeAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: Colors.white10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Skills list
                              Expanded(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: (dev['skills'] as List<String>).map((skill) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.04),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        skill,
                                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              Text(
                                dev['experience'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigoAccent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Placeholder for adding listing
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Add developer listing functionality coming soon!'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
        backgroundColor: Colors.indigoAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavigationIndex,
        backgroundColor: const Color(0xFF1C1A18),
        indicatorColor: Colors.indigoAccent.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_rounded),
            label: 'Listings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
        onDestinationSelected: (index) {
          setState(() {
            _currentNavigationIndex = index;
          });
        },
      ),
    );
  }
}
