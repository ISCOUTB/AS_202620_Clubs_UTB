import 'package:flutter/material.dart';
import 'package:linkclub/core/session/session_controller.dart';
import 'package:linkclub/core/theme/theme_controller.dart';
import 'package:linkclub/data/auth_repository.dart';
import 'package:linkclub/data/club_repository.dart';
import 'package:linkclub/presentation/clubs_details.dart';
import 'package:linkclub/presentation/dev_admin_screen.dart';
import 'package:linkclub/presentation/feed_screen.dart';
import 'package:linkclub/presentation/login_screen.dart';
import 'package:linkclub/presentation/events_screen.dart';

class ClubsPage extends StatefulWidget {
  const ClubsPage({super.key});

  @override
  State<ClubsPage> createState() => _ClubsPageState();
}

class _ClubsPageState extends State<ClubsPage> {
  static const String _fontFamily = 'DMSans';
  static const Color _darkBg = Color(0xFF080C14);
  static const Color _darkSurface = Color(0xFF0F1623);
  static const Color _darkElevated = Color(0xFF131B2E);
  static const Color _darkBorder = Color(0xFF1E293B);
  static const Color _darkTextPrimary = Color(0xFFE2E8F0);
  static const Color _darkTextSecondary = Color(0xFF8A99AD);

  static const Color _lightBg = Color(0xFFF8FAFC);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightElevated = Color(0xFFF1F5F9);
  static const Color _lightBorder = Color(0xFFE2E8F0);
  static const Color _lightTextPrimary = Color(0xFF0F172A);
  static const Color _lightTextSecondary = Color(0xFF64748B);

  static const Color _brandBlue = Color(0xFF1D4ED8);
  static const Color _brandBlueSoft = Color(0xFF60A5FA);

  int _currentIndex = 0;

  final List<Widget> _pages = const [
    FeedScreen(),
    EventsScreen(),
    ClubsListScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? _darkBg : _lightBg;
    final headerBg = isDarkMode ? _darkBg : _lightSurface;
    final borderColor = isDarkMode ? _darkBorder : _lightBorder;
    final titleColor = isDarkMode ? _darkTextPrimary : _lightTextPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(62),
        child: Container(
          decoration: BoxDecoration(
            color: headerBg,
            border: Border(bottom: BorderSide(color: borderColor, width: 1)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isDarkMode ? _darkElevated : _lightSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.asset(
                            'assets/icon/logo_clean.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'LinkClub',
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                  Material(
                    color: isDarkMode ? _darkElevated : _lightElevated,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: borderColor, width: 1),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => ThemeController.toggle(),
                      child: SizedBox(
                        width: 38,
                        height: 38,
                        child: Icon(
                          isDarkMode
                              ? Icons.wb_sunny_outlined
                              : Icons.dark_mode_rounded,
                          size: 19,
                          color: isDarkMode
                              ? const Color(0xFFEAB308)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        color: bgColor,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDarkMode ? _darkSurface : _lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Row(
                children: [
                  _buildNavItem(
                    index: 0,
                    label: 'Feed',
                    icon: Icons.dynamic_feed_outlined,
                    activeIcon: Icons.dynamic_feed_rounded,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(width: 4),
                  _buildNavItem(
                    index: 1,
                    label: 'Eventos',
                    icon: Icons.event_outlined,
                    activeIcon: Icons.event_rounded,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(width: 4),
                  _buildNavItem(
                    index: 2,
                    label: 'Clubes',
                    icon: Icons.groups_outlined,
                    activeIcon: Icons.groups_rounded,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(width: 4),
                  _buildNavItem(
                    index: 3,
                    label: 'Ajustes',
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings_rounded,
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required bool isDarkMode,
  }) {
    final isSelected = _currentIndex == index;
    final activeBg = isDarkMode
        ? _brandBlue.withValues(alpha: 0.18)
        : _brandBlue.withValues(alpha: 0.10);
    final activeBorder = isDarkMode
        ? const Color(0xFF3B82F6).withValues(alpha: 0.30)
        : _brandBlue.withValues(alpha: 0.22);
    final activeColor = isDarkMode ? _brandBlueSoft : _brandBlue;
    final inactiveColor = isDarkMode ? _darkTextSecondary : _lightTextSecondary;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? activeBorder : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 20,
                color: isSelected ? activeColor : inactiveColor,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
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
  static const String _fontFamily = 'DMSans';
  static const Color _darkSurface = Color(0xFF0F1623);
  static const Color _darkElevated = Color(0xFF131B2E);
  static const Color _darkBorder = Color(0xFF1E293B);
  static const Color _darkTextPrimary = Color(0xFFF1F5F9);
  static const Color _darkTextSecondary = Color(0xFF94A3B8);

  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightElevated = Color(0xFFF1F5F9);
  static const Color _lightBorder = Color(0xFFE2E8F0);
  static const Color _lightTextPrimary = Color(0xFF0F172A);
  static const Color _lightTextSecondary = Color(0xFF64748B);

  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _softBlue = Color(0xFF60A5FA);

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode ? _darkSurface : _lightSurface;
    final elevatedColor = isDarkMode ? _darkElevated : _lightElevated;
    final borderColor = isDarkMode ? _darkBorder : _lightBorder;
    final textPrimary = isDarkMode ? _darkTextPrimary : _lightTextPrimary;
    final textSecondary = isDarkMode ? _darkTextSecondary : _lightTextSecondary;
    final accentColor = isDarkMode ? _softBlue : _primaryBlue;
    final filtrados = _clubesFiltrados;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clubes disponibles',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                  ],
                ),
              ),
              if (!_isLoading && _errorMensaje == null) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _primaryBlue.withValues(
                      alpha: isDarkMode ? 0.16 : 0.09,
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _primaryBlue.withValues(alpha: 0.30),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.groups_rounded, size: 14, color: accentColor),
                      const SizedBox(width: 5),
                      Text(
                        '${filtrados.length}',
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _queryBusqueda = value.trim()),
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 14,
              color: textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, categoría o tema...',
              hintStyle: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 14,
                color: textSecondary,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color: textSecondary,
              ),
              suffixIcon: _queryBusqueda.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: textSecondary,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _queryBusqueda = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: surfaceColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
              ),
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
                  return GestureDetector(
                    onTap: () => setState(() => _categoriaSeleccionada = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: seleccionada ? _primaryBlue : surfaceColor,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: seleccionada ? _primaryBlue : borderColor,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 12.5,
                            fontWeight: seleccionada
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: seleccionada ? Colors.white : textSecondary,
                          ),
                        ),
                      ),
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
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            size: 42,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _errorMensaje!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 14,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _cargarClubes,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargarClubes,
                    color: accentColor,
                    child: filtrados.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 80),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 42,
                                      color: textSecondary.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _todosLosClubes.isEmpty
                                          ? 'No hay clubes registrados en la base de datos.'
                                          : 'No se encontraron clubes con ese filtro.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: _fontFamily,
                                        fontSize: 14,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 20),
                            itemCount: filtrados.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final club = filtrados[index];
                              return _buildClubDirectoryCard(
                                club: club,
                                isDarkMode: isDarkMode,
                                surfaceColor: surfaceColor,
                                elevatedColor: elevatedColor,
                                borderColor: borderColor,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                accentColor: accentColor,
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubDirectoryCard({
    required ClubModel club,
    required bool isDarkMode,
    required Color surfaceColor,
    required Color elevatedColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
  }) {
    return Material(
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _abrirDetalleClub(club),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryBlue.withValues(alpha: 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      club.iconoCategoria,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _primaryBlue.withValues(
                                  alpha: isDarkMode ? 0.16 : 0.08,
                                ),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: _primaryBlue.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                club.categoria,
                                style: TextStyle(
                                  fontFamily: _fontFamily,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: accentColor,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (club.inscripcionesAbiertas)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 3,
                                      backgroundColor: Color(0xFF34D399),
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Abierto',
                                      style: TextStyle(
                                        fontFamily: _fontFamily,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF34D399),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          club.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          club.descripcion,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 13,
                            height: 1.4,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: elevatedColor,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: borderColor.withValues(alpha: 0.7),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 14, color: accentColor),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        club.horario,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: accentColor,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        club.lugar,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: _primaryBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 15,
                        color: Colors.white,
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
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String _fontDisplay = 'DMSans';
  static const String _fontBody = 'DMSans';

  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _deepSapphire = Color(0xFF004AC6);
  static const Color _softBlue = Color(0xFF60A5FA);
  static const Color _secondaryIndigo = Color(0xFF3323CC);
  static const Color _secondaryFixed = Color(0xFFE2DFFF);

  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurfaceLow = Color(0xFFEFF4FF);
  static const Color _lightSurfaceHigh = Color(0xFFDCE9FF);
  static const Color _lightBorder = Color(0xFFE2E8F0);
  static const Color _lightTextPrimary = Color(0xFF0B1C30);
  static const Color _lightTextSecondary = Color(0xFF434655);

  static const Color _darkSurface = Color(0xFF0F1623);
  static const Color _darkElevated = Color(0xFF131B2E);
  static const Color _darkBorder = Color(0xFF1E293B);
  static const Color _darkTextPrimary = Color(0xFFF1F5F9);
  static const Color _darkTextSecondary = Color(0xFF94A3B8);

  static const Color _errorRed = Color(0xFFBA1A1A);
  static const Color _errorContainer = Color(0xFFFFDAD6);

  Future<void> _signOut(BuildContext context) async {
    await SessionController.instance.cerrarSesion();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  void _abrirEditarPerfil(BuildContext context, UsuarioSesion usuario) {
    final nombreCtrl = TextEditingController(text: usuario.nombre);
    final descCtrl = TextEditingController(text: usuario.descripcion ?? '');
    final authRepo = AuthRepository();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Editar Perfil Institucional',
          style: TextStyle(
            fontFamily: _fontDisplay,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: InputDecoration(
                labelText: 'Nombre completo',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Biografía o descripción (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              try {
                await authRepo.actualizarMiPerfil(
                  nombre: nombreCtrl.text.trim(),
                  descripcion: descCtrl.text.trim(),
                );
                await SessionController.instance.cargarSesion();
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Perfil actualizado'),
                      backgroundColor: Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al actualizar perfil: $e'),
                      backgroundColor: _errorRed,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _abrirCambiarPassword(BuildContext context) {
    final actualCtrl = TextEditingController();
    final nuevaCtrl = TextEditingController();
    final authRepo = AuthRepository();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cambiar contraseña',
          style: TextStyle(
            fontFamily: _fontDisplay,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: actualCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Contraseña actual',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nuevaCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nueva contraseña (mín. 8 caracteres)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              if (nuevaCtrl.text.length < 8) return;
              try {
                await authRepo.cambiarPassword(actualCtrl.text, nuevaCtrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contraseña actualizada correctamente'),
                      backgroundColor: Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('La contraseña actual no es correcta'),
                      backgroundColor: _errorRed,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarEliminarCuenta(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminar cuenta',
          style: TextStyle(
            fontFamily: _fontDisplay,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Esta acción es permanente y eliminará tu acceso institucional a LinkClub. ¿Deseas continuar?',
          style: TextStyle(fontFamily: _fontBody, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _errorRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar definitivamente'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await AuthRepository().eliminarMiCuenta();
      await SessionController.instance.cerrarSesion();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode ? _darkSurface : _lightSurface;
    final elevatedColor = isDarkMode ? _darkElevated : _lightSurfaceHigh;
    final pillBg = isDarkMode ? _darkElevated : _lightSurfaceLow;
    final borderColor = isDarkMode ? _darkBorder : _lightBorder;
    final textPrimary = isDarkMode ? _darkTextPrimary : _lightTextPrimary;
    final textSecondary = isDarkMode ? _darkTextSecondary : _lightTextSecondary;
    final accentColor = isDarkMode ? _softBlue : _deepSapphire;

    return ListenableBuilder(
      listenable: SessionController.instance,
      builder: (context, _) {
        final session = SessionController.instance;
        final usuario = session.usuario;

        String etiquetaRol = 'Estudiante UTB';
        if (session.esSuperAdminReal) {
          etiquetaRol = 'Superadmin (Desarrollador)';
        } else if (session.esAdminClubReal) {
          etiquetaRol =
              'Admin de Club: ${usuario?.clubAdministradoNombre ?? 'Verificado'}';
        } else if (usuario?.solicitudPendiente == true) {
          etiquetaRol = 'Estudiante (Solicitud de Admin pendiente)';
        }

        final List<Widget> opcionesCuenta = [];

        if (session.esSuperAdminReal) {
          opcionesCuenta.add(
            _buildAccountMenuItem(
              icon: Icons.terminal_rounded,
              title: 'Consola Desarrollador',
              subtitle: 'Aprobar admins y crear clubes',
              badgeText: 'Admin',
              isDarkMode: isDarkMode,
              elevatedColor: elevatedColor,
              accentColor: accentColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DevAdminScreen()),
                );
              },
            ),
          );
        }

        if (session.esAdminClubReal && usuario?.clubAdministradoId != null) {
          opcionesCuenta.add(
            _buildAccountMenuItem(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Gestionar mi club',
              subtitle: usuario?.clubAdministradoNombre ?? '',
              badgeText: 'Club',
              isDarkMode: isDarkMode,
              elevatedColor: elevatedColor,
              accentColor: accentColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onTap: () async {
                final club = await ClubRepository().obtenerClubPorId(
                  usuario!.clubAdministradoId!,
                );
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClubDetailPage(club: club),
                    ),
                  );
                }
              },
            ),
          );
        }

        if (usuario != null) {
          opcionesCuenta.add(
            _buildAccountMenuItem(
              icon: Icons.badge_outlined,
              title: 'Editar Perfil Institucional',
              isDarkMode: isDarkMode,
              elevatedColor: elevatedColor,
              accentColor: accentColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onTap: () => _abrirEditarPerfil(context, usuario),
            ),
          );
          opcionesCuenta.add(
            _buildAccountMenuItem(
              icon: Icons.lock_reset_rounded,
              title: 'Cambiar contraseña',
              isDarkMode: isDarkMode,
              elevatedColor: elevatedColor,
              accentColor: accentColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onTap: () => _abrirCambiarPassword(context),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configuración y Perfil',
                style: TextStyle(
                  fontFamily: _fontDisplay,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),

              // Tarjeta Principal de Perfil
              if (usuario != null)
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFF0F172A,
                        ).withValues(alpha: isDarkMode ? 0.25 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -24,
                          top: -24,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _primaryBlue.withValues(
                                alpha: isDarkMode ? 0.14 : 0.07,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [_primaryBlue, _deepSapphire],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryBlue.withValues(
                                        alpha: 0.28,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    usuario.nombre.isNotEmpty
                                        ? usuario.nombre[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontFamily: _fontDisplay,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      usuario.nombre,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: _fontDisplay,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${usuario.matricula} • ${usuario.correo}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: _fontBody,
                                        fontSize: 12.5,
                                        color: textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: pillBg,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: _primaryBlue.withValues(
                                            alpha: 0.22,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.verified_user_rounded,
                                            size: 14,
                                            color: accentColor,
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              etiquetaRol,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: _fontBody,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: accentColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Tarjeta Modo Vista Estudiante
              if (session.esAdminClubReal || session.esSuperAdminReal) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: pillBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.visibility_outlined,
                          size: 21,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Modo Vista Estudiante',
                              style: TextStyle(
                                fontFamily: _fontDisplay,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Previsualiza la vista estudiantil',
                              style: TextStyle(
                                fontFamily: _fontBody,
                                fontSize: 12.5,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: session.forzarVistaEstudiante,
                        activeColor: _primaryBlue,
                        onChanged: session.alternarVistaEstudiante,
                      ),
                    ],
                  ),
                ),
              ],

              // Grupo: MI CUENTA
              if (opcionesCuenta.isNotEmpty) ...[
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'MI CUENTA',
                    style: TextStyle(
                      fontFamily: _fontBody,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.9,
                      color: textSecondary,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < opcionesCuenta.length; i++) ...[
                        opcionesCuenta[i],
                        if (i < opcionesCuenta.length - 1)
                          Divider(
                            height: 1,
                            thickness: 1,
                            indent: 16,
                            endIndent: 16,
                            color: borderColor.withValues(alpha: 0.7),
                          ),
                      ],
                    ],
                  ),
                ),
              ],

              // Grupo: Acciones de Sesión y Cuenta
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Column(
                  children: [
                    if (usuario != null) ...[
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          onTap: () => _confirmarEliminarCuenta(context),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? _errorRed.withValues(alpha: 0.2)
                                        : _errorContainer.withValues(
                                            alpha: 0.65,
                                          ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 20,
                                    color: isDarkMode
                                        ? const Color(0xFFFFB4AB)
                                        : _errorRed,
                                  ),
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Text(
                                    'Eliminar cuenta',
                                    style: TextStyle(
                                      fontFamily: _fontDisplay,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode
                                          ? const Color(0xFFFFB4AB)
                                          : _errorRed,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color:
                                      (isDarkMode
                                              ? const Color(0xFFFFB4AB)
                                              : _errorRed)
                                          .withValues(alpha: 0.65),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: borderColor.withValues(alpha: 0.7),
                      ),
                    ],
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.vertical(
                          top: usuario == null
                              ? const Radius.circular(16)
                              : Radius.zero,
                          bottom: const Radius.circular(16),
                        ),
                        onTap: () => _signOut(context),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _errorRed,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.logout_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Text(
                                  'Cerrar sesión',
                                  style: TextStyle(
                                    fontFamily: _fontDisplay,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDarkMode
                                        ? const Color(0xFFFFB4AB)
                                        : _errorRed,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.logout_rounded,
                                size: 20,
                                color: isDarkMode
                                    ? const Color(0xFFFFB4AB)
                                    : _errorRed,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Pie Institucional
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Universidad Tecnológica de Bolívar',
                  style: TextStyle(
                    fontFamily: _fontBody,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textSecondary.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    String? badgeText,
    required bool isDarkMode,
    required Color elevatedColor,
    required Color accentColor,
    required Color textPrimary,
    required Color textSecondary,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: elevatedColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 21, color: accentColor),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: _fontDisplay,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _fontBody,
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (badgeText != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF4B41E1).withValues(alpha: 0.25)
                        : _secondaryFixed,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontFamily: _fontBody,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode
                          ? const Color(0xFFC3C0FF)
                          : _secondaryIndigo,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: textSecondary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
