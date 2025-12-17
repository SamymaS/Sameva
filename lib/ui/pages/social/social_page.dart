import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/glassmorphic_card.dart';
import '../../widgets/figma/fantasy_badge.dart';

/// Page Social - Liste d'amis, visite de profil, envoi d'encouragements (Cœurs)
/// Selon pages.md : "Social : Liste d'amis, visite de profil, envoi d'encouragements (Cœurs)"
class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  // Données d'exemple - À remplacer par des données réelles depuis Supabase
  final List<Map<String, dynamic>> _friends = [
    {
      'id': '1',
      'name': 'Alexandre',
      'avatar': null,
      'level': 15,
      'streak': 7,
      'lastActive': DateTime.now().subtract(const Duration(minutes: 5)),
      'heartsReceived': 3,
    },
    {
      'id': '2',
      'name': 'Sophie',
      'avatar': null,
      'level': 22,
      'streak': 14,
      'lastActive': DateTime.now().subtract(const Duration(hours: 2)),
      'heartsReceived': 5,
    },
    {
      'id': '3',
      'name': 'Thomas',
      'avatar': null,
      'level': 8,
      'streak': 3,
      'lastActive': DateTime.now().subtract(const Duration(days: 1)),
      'heartsReceived': 1,
    },
  ];

  final List<Map<String, dynamic>> _pendingRequests = [
    {
      'id': '4',
      'name': 'Marie',
      'avatar': null,
      'level': 12,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNightBlue,
      body: SafeArea(
        child: Column(
          children: [
            // En-tête avec recherche
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Cercle Social',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_add_outlined),
                        color: AppColors.primaryTurquoise,
                        onPressed: () => _showAddFriendDialog(context),
                        tooltip: 'Ajouter un ami',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un ami...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: AppColors.backgroundDarkPanel.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.inputBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.inputBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.primaryTurquoise,
                          width: 2,
                        ),
                      ),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryTurquoise,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primaryTurquoise,
              tabs: const [
                Tab(text: 'Amis'),
                Tab(text: 'Demandes'),
                Tab(text: 'Recherche'),
              ],
            ),
            // Contenu des tabs
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFriendsTab(),
                  _buildRequestsTab(),
                  _buildSearchTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsTab() {
    final filteredFriends = _friends.where((friend) {
      if (_searchQuery.isEmpty) return true;
      return friend['name']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredFriends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Aucun ami pour le moment'
                  : 'Aucun ami trouvé',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showAddFriendDialog(context),
              icon: const Icon(Icons.person_add),
              label: const Text('Ajouter un ami'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredFriends.length,
      itemBuilder: (context, index) {
        final friend = filteredFriends[index];
        return _buildFriendCard(friend);
      },
    );
  }

  Widget _buildRequestsTab() {
    if (_pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune demande en attente',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildSearchTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Recherche d\'amis',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fonctionnalité à venir',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friend) {
    final lastActive = friend['lastActive'] as DateTime;
    final isOnline = DateTime.now().difference(lastActive).inMinutes < 15;

    return GlassmorphicCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primaryTurquoise.withOpacity(0.2),
              child: friend['avatar'] != null
                  ? ClipOval(
                      child: Image.network(
                        friend['avatar'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildAvatarFallback(friend['name']),
                      ),
                    )
                  : _buildAvatarFallback(friend['name']),
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.backgroundNightBlue,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          friend['name'],
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                FantasyBadge(
                  label: 'Niv. ${friend['level']}',
                  variant: BadgeVariant.secondary,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
                const SizedBox(width: 6),
                FantasyBadge(
                  label: '🔥 ${friend['streak']}',
                  variant: BadgeVariant.default_,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isOnline
                  ? 'En ligne'
                  : 'Dernière connexion: ${_formatLastActive(lastActive)}',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouton Cœur (encouragement)
            IconButton(
              icon: Icon(
                Icons.favorite,
                color: AppColors.error,
              ),
              onPressed: () => _sendHeart(friend['id']),
              tooltip: 'Envoyer un cœur',
            ),
            // Bouton Visiter profil
            IconButton(
              icon: const Icon(Icons.person_outline),
              color: AppColors.primaryTurquoise,
              onPressed: () => _visitProfile(friend['id']),
              tooltip: 'Voir le profil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    return GlassmorphicCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primaryTurquoise.withOpacity(0.2),
          child: request['avatar'] != null
              ? ClipOval(
                  child: Image.network(
                    request['avatar'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildAvatarFallback(request['name']),
                  ),
                )
              : _buildAvatarFallback(request['name']),
        ),
        title: Text(
          request['name'],
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Row(
          children: [
            FantasyBadge(
              label: 'Niv. ${request['level']}',
              variant: BadgeVariant.secondary,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: AppColors.success),
              onPressed: () => _acceptRequest(request['id']),
              tooltip: 'Accepter',
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.error),
              onPressed: () => _rejectRequest(request['id']),
              tooltip: 'Refuser',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: TextStyle(
        color: AppColors.primaryTurquoise,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    );
  }

  String _formatLastActive(DateTime lastActive) {
    final difference = DateTime.now().difference(lastActive);
    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else {
      return 'Il y a ${difference.inDays} j';
    }
  }

  void _sendHeart(String friendId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.favorite, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Cœur envoyé ! ❤️'),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
    // TODO: Implémenter l'envoi de cœur via Supabase
  }

  void _visitProfile(String friendId) {
    // TODO: Naviguer vers la page de profil de l'ami
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Visite du profil de l\'ami $friendId'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _acceptRequest(String requestId) {
    setState(() {
      _pendingRequests.removeWhere((req) => req['id'] == requestId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demande acceptée'),
        backgroundColor: AppColors.success,
      ),
    );
    // TODO: Implémenter l'acceptation via Supabase
  }

  void _rejectRequest(String requestId) {
    setState(() {
      _pendingRequests.removeWhere((req) => req['id'] == requestId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demande refusée'),
        backgroundColor: AppColors.error,
      ),
    );
    // TODO: Implémenter le refus via Supabase
  }

  void _showAddFriendDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundDarkPanel,
        title: const Text(
          'Ajouter un ami',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Nom d\'utilisateur ou email',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.backgroundNightBlue,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.inputBorder),
            ),
          ),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Demande d\'ami envoyée'),
                  backgroundColor: AppColors.info,
                ),
              );
              // TODO: Implémenter l'envoi de demande via Supabase
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}
