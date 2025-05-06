import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_connect/config/route.dart';
import 'package:campus_connect/providers/auth_provider.dart';
import 'package:campus_connect/providers/faculty_provider.dart';
import 'package:campus_connect/providers/appointment_provider.dart';
import 'package:campus_connect/widgets/faculty_card.dart';
import 'package:campus_connect/widgets/loading_indicator.dart';
import 'package:campus_connect/widgets/error_display.dart';
import 'package:campus_connect/widgets/empty_state.dart';
import 'package:campus_connect/widgets/animated_list_item.dart';
import 'package:campus_connect/config/theme.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({Key? key}) : super(key: key);

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLoading = false;
  final _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadFacultyList();

      final appointmentProvider = Provider.of<AppointmentProvider>(
        context,
        listen: false,
      );
      await appointmentProvider.fetchStudentAppointments();
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFacultyList() async {
    final facultyProvider = Provider.of<FacultyProvider>(
      context,
      listen: false,
    );
    await facultyProvider.fetchFacultyList();
  }

  Future<void> _searchFaculty(String query) async {
    if (query.isEmpty) {
      await _loadFacultyList();
      return;
    }

    final facultyProvider = Provider.of<FacultyProvider>(
      context,
      listen: false,
    );
    await facultyProvider.searchFaculty(query);
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.logout();

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRouter.roleSelectionRoute, (route) => false);
    } else {
      _showSnackBar(authProvider.error ?? 'Logout failed');
    }
  }

  void _navigateToFacultyDetail(String facultyId, String facultyName) {
    Navigator.of(context).pushNamed(
      AppRouter.facultyDetailRoute,
      arguments: {'facultyId': facultyId, 'facultyName': facultyName},
    );
  }

  void _navigateToAppointmentHistory() {
    Navigator.of(context).pushNamed(AppRouter.appointmentHistoryRoute);
  }

  void _navigateToProfile() {
    Navigator.of(context).pushNamed(AppRouter.studentProfileRoute);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final facultyProvider = Provider.of<FacultyProvider>(context);
    final appointmentProvider = Provider.of<AppointmentProvider>(context);
    final studentProfile = authProvider.studentProfile;

    final upcomingAppointments = appointmentProvider.getUpcomingAppointments();
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search faculty...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  autofocus: true,
                  onChanged: _searchFaculty,
                )
                : const Text('Faculty List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _loadFacultyList();
                }
              });
            },
            tooltip: _isSearching ? 'Cancel' : 'Search',
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: _navigateToAppointmentHistory,
                tooltip: 'Appointment History',
              ),
              if (upcomingAppointments.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${upcomingAppointments.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _navigateToProfile,
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
        elevation: 4,
      ),
      body:
          _isLoading
              ? const LoadingIndicator(message: 'Loading data...')
              : SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (studentProfile != null)
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppTheme.primaryColor
                                        .withOpacity(0.2),
                                    child: Text(
                                      studentProfile.name.isNotEmpty
                                          ? studentProfile.name[0].toUpperCase()
                                          : 'S',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Welcome, ${studentProfile.name}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${studentProfile.course} - ${studentProfile.branch}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Year ${studentProfile.currentYear}, Semester ${studentProfile.currentSemester}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (upcomingAppointments.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: _navigateToAppointmentHistory,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.notifications_active,
                                          color: AppTheme.primaryColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'You have ${upcomingAppointments.length} upcoming appointment${upcomingAppointments.length > 1 ? 's' : ''}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: Colors.grey[400],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    Expanded(
                      child:
                          facultyProvider.isLoading ||
                                  appointmentProvider.isLoading
                              ? const LoadingIndicator()
                              : facultyProvider.error != null
                              ? ErrorDisplay(
                                message: 'Error: ${facultyProvider.error}',
                                onRetry: _loadData,
                              )
                              : facultyProvider.facultyList.isEmpty
                              ? EmptyState(
                                message: 'No faculty members found',
                                subMessage:
                                    _isSearching
                                        ? 'Try a different search term'
                                        : 'Pull down to refresh',
                                icon: Icons.people_outline,
                                onAction: _loadData,
                                actionLabel: 'Refresh',
                              )
                              : RefreshIndicator(
                                onRefresh: _loadData,
                                color: AppTheme.primaryColor,
                                child: ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: facultyProvider.facultyList.length,
                                  itemBuilder: (context, index) {
                                    final faculty =
                                        facultyProvider.facultyList[index];
                                    return AnimatedListItem(
                                      delay: Duration(milliseconds: 50 * index),
                                      child: FacultyCard(
                                        faculty: faculty,
                                        onTap:
                                            () => _navigateToFacultyDetail(
                                              faculty.id,
                                              faculty.name,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                    ),
                  ],
                ),
              ),
    );
  }
}
