import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:linkclub/core/theme/theme_controller.dart';
import 'package:linkclub/data/club_repository.dart';
import 'package:linkclub/presentation/clubs_details.dart';
import 'package:linkclub/presentation/feed_screen.dart';
import 'package:linkclub/presentation/login_screen.dart';

class ClubsPage extends StatefulWidget {
  const ClubsPage({super.key});

  @override
  State<ClubsPage> createState() => _ClubsPageState();
}

class _ClubsPageState extends State<ClubsPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    FeedScreen(),
    EventsScreen(),
    ClubsListScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          title: Row(
            children: [
              Image.asset(
                'assets/icon/logo_clean.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Text(
                'LinkClub',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: colorScheme.onSurface,
              ),
              onPressed: () => ThemeController.toggle(),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.scaffoldBackgroundColor,
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: colorScheme.onSurface.withOpacity(0.4),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dynamic_feed_outlined),
              activeIcon: Icon(Icons.dynamic_feed_rounded),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_outlined),
              activeIcon: Icon(Icons.event_rounded),
              label: 'Eventos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              activeIcon: Icon(Icons.groups_rounded),
              label: 'Clubes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_rounded),
              activeIcon: Icon(Icons.menu_rounded),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }
}

class ClubsListScreen extends StatefulWidget {
  const ClubsListScreen({super.key});

  @override
  State<ClubsListScreen> createState() => _ClubsListScreenState();
}

class _ClubsListScreenState extends State<ClubsListScreen> {
  final ClubRepository _clubRepository = ClubRepository();
  final TextEditingController _searchController = TextEditingController();

  List<ClubModel> _todosLosClubes = [];
  String _categoriaSeleccionada = 'Todos';
  String _queryBusqueda = '';
  bool _isLoading = true;
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    _cargarClubes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarClubes() async {
    setState(() {
      _isLoading = true;
      _errorMensaje = null;
    });

    try {
      final clubes = await _clubRepository.obtenerClubes();
      if (mounted) {
        setState(() {
          _todosLosClubes = clubes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMensaje = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  List<String> get _categoriasDisponibles {
    final cats = <String>{'Todos'};
    for (final c in _todosLosClubes) {
      if (c.categoria.trim().isNotEmpty) {
        cats.add(c.categoria.trim());
      }
    }
    return cats.toList();
  }

  List<ClubModel> get _clubesFiltrados {
    return _todosLosClubes.where((club) {
      final coincideCategoria =
          _categoriaSeleccionada == 'Todos' ||
          club.categoria.toLowerCase() == _categoriaSeleccionada.toLowerCase();

      final q = _queryBusqueda.toLowerCase();
      final coincideTexto =
          q.isEmpty ||
          club.nombre.toLowerCase().contains(q) ||
          club.categoria.toLowerCase().contains(q) ||
          club.descripcion.toLowerCase().contains(q);

      return coincideCategoria && coincideTexto;
    }).toList();
  }

  void _abrirDetalleClub(ClubModel club) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ClubDetailPage(club: club)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filtrados = _clubesFiltrados;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Clubes disponibles',
                style: theme.textTheme.displayLarge?.copyWith(fontSize: 24),
              ),
              if (!_isLoading && _errorMensaje == null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${filtrados.length}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Explora y conéctate con los clubes activos de la UTB',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _queryBusqueda = value.trim()),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, categoría o tema...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _queryBusqueda.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _queryBusqueda = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          if (!_isLoading && _categoriasDisponibles.length > 1) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categoriasDisponibles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categoriasDisponibles[index];
                  final seleccionada = cat == _categoriaSeleccionada;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: seleccionada,
                    onSelected: (_) =>
                        setState(() => _categoriaSeleccionada = cat),
                    selectedColor: colorScheme.primary,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: seleccionada
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 14),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMensaje != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 44,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMensaje!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _cargarClubes,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargarClubes,
                    color: colorScheme.primary,
                    child: filtrados.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 100),
                              Center(
                                child: Text(
                                  _todosLosClubes.isEmpty
                                      ? 'No hay clubes registrados en la base de datos.'
                                      : 'No se encontraron clubes con ese filtro.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            itemCount: filtrados.length,
                            itemBuilder: (context, index) {
                              final club = filtrados[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _abrirDetalleClub(club),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          child: Icon(
                                            club.iconoCategoria,
                                            color: colorScheme.primary,
                                            size: 26,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                club.nombre,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                club.categoria,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: colorScheme.primary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                club.descripcion,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: colorScheme.onSurface
                                                      .withOpacity(0.65),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        SizedBox(
                                          height: 36,
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                _abrirDetalleClub(club),
                                            style: ElevatedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: const Text(
                                              'Ver',
                                              style: TextStyle(fontSize: 13),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Eventos Disponibles',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'jwt_token');

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuracion y Perfil',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: const Text('Mi Perfil Institucional'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notificaciones'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
          const Spacer(),
          Divider(color: colorScheme.onSurface.withOpacity(0.1)),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text(
              'Cerrar sesion',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => _signOut(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
