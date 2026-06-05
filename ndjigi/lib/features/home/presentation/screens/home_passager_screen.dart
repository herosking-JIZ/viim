import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/providers/app_providers.dart';

class HomePassagerScreen extends ConsumerStatefulWidget {
  const HomePassagerScreen({super.key});

  @override
  ConsumerState<HomePassagerScreen> createState() =>
      _HomePassagerScreenState();
}

class _HomePassagerScreenState extends ConsumerState<HomePassagerScreen> {
  late int _selectedNavIndex;
  late int _currentCarouselPage;
  late PageController _pageController;
  Map<String, dynamic>? _walletData;
  List<dynamic>? _notifications;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedNavIndex = 0;
    _currentCarouselPage = 0;
    _pageController = PageController();
    _startAutoScroll();
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 4)).then((_) {
      if (mounted && _pageController.hasClients) {
        int nextPage = (_currentCarouselPage + 1) % 3;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _startAutoScroll();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final apiService = ref.read(apiServiceProvider);

      final futures = await Future.wait(
        [
          apiService.get<Map<String, dynamic>>('/utilisateurs/profil')
              .catchError((_) => <String, dynamic>{}),
          apiService.get<Map<String, dynamic>>('/paiement/portefeuille')
              .catchError((_) => <String, dynamic>{}),
          apiService.get<Map<String, dynamic>>('/notification')
              .catchError((_) => <String, dynamic>{}),
        ],
        eagerError: false,
      );

      setState(() {
        _walletData = futures[1];
        final notifResponse = futures[2];
        _notifications = notifResponse['notifications'] as List<dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des données';
        _isLoading = false;
      });
    }
  }

  int _getUnreadNotificationCount() {
    if (_notifications == null) return 0;
    return _notifications!
        .where((n) => n is Map && n['lue'] == false)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('N\'DJIGI')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('N\'DJIGI')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final unreadCount = _getUnreadNotificationCount();
    final solde = _walletData?['solde'] ?? 0;
    final devise = _walletData?['devise'] ?? 'FCFA';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A651),
        leading: Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () => context.push('/notifications'),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: const Text(
          'N\'DJIGI',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                authState.user?.prenom?.isNotEmpty == true
                    ? authState.user!.prenom![0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Color(0xFF00A651)),
              ),
            ),
            onPressed: () => context.push('/profil'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Carousel Banner
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  SizedBox(
                    height: 150,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentCarouselPage = index);
                      },
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF00A651),
                                  const Color(0xFF00A651).withValues(alpha: 0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Banner ${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Row(
                      children: List.generate(
                        3,
                        (index) => Container(
                          height: 6,
                          width: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: _currentCarouselPage == index
                                ? const Color(0xFF00A651)
                                : Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Wallet Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00A651),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Color(0xFF00A651),
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Portefeuille',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$solde $devise',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => context.push('/paiement/recharge'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Recharger',
                        style: TextStyle(
                          color: Color(0xFF00A651),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Services Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildServiceCard(
                    icon: Icons.local_taxi,
                    label: 'VTC',
                    onTap: () => context.push('/course/destination-search'),
                  ),
                  _buildServiceCard(
                    icon: Icons.groups,
                    label: 'Covoiturage',
                    onTap: () => context.push('/covoiturage/search'),
                  ),
                  _buildServiceCard(
                    icon: Icons.calendar_today,
                    label: 'Réservation',
                    onTap: () => context.push('/reservation/form'),
                  ),
                  _buildServiceCard(
                    icon: Icons.directions_car,
                    label: 'Location',
                    onTap: () => context.push('/location/search'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        selectedItemColor: const Color(0xFF00A651),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Trajets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Location',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        onTap: (index) {
          setState(() => _selectedNavIndex = index);
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              context.push('/course/history');
              break;
            case 2:
              context.push('/location/search');
              break;
            case 3:
              context.push('/profil');
              break;
          }
        },
      ),
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: const Color(0xFF00A651),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
