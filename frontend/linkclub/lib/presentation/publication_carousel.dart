import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PublicationCarouselItem {
  final String pathOrUrl;
  final bool isLocalFile;

  const PublicationCarouselItem({
    required this.pathOrUrl,
    this.isLocalFile = false,
  });
}

class PublicationCarousel extends StatefulWidget {
  final List<PublicationCarouselItem> items;
  final bool isDarkMode;
  final double height;
  final BorderRadius? borderRadius;
  final bool showHorizontalBorders;
  final void Function(int index)? onRemoveAt;

  const PublicationCarousel({
    super.key,
    required this.items,
    required this.isDarkMode,
    this.height = 310,
    this.borderRadius,
    this.showHorizontalBorders = true,
    this.onRemoveAt,
  });

  @override
  State<PublicationCarousel> createState() => _PublicationCarouselState();
}

class _PublicationCarouselState extends State<PublicationCarousel> {
  static const Color _darkElevated = Color(0xFF131B2E);
  static const Color _darkBorder = Color(0xFF1E293B);
  static const Color _lightElevated = Color(0xFFF1F5F9);
  static const Color _lightBorder = Color(0xFFE2E8F0);
  static const Color _brandBlue = Color(0xFF2563EB);
  static const Color _brandBlueSoft = Color(0xFF60A5FA);

  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(covariant PublicationCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentIndex >= widget.items.length && widget.items.isNotEmpty) {
      _currentIndex = widget.items.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentIndex);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _irAPagina(int index) {
    if (index < 0 || index >= widget.items.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildImage(PublicationCarouselItem item, Color accentColor) {
    if (item.isLocalFile) {
      if (kIsWeb) {
        return Image.network(
          item.pathOrUrl,
          fit: BoxFit.contain,
          width: double.infinity,
          height: widget.height,
        );
      }
      return Image.file(
        File(item.pathOrUrl),
        fit: BoxFit.contain,
        width: double.infinity,
        height: widget.height,
      );
    }

    return Image.network(
      item.pathOrUrl,
      fit: BoxFit.contain,
      width: double.infinity,
      height: widget.height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: accentColor,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 32,
          color: accentColor.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final bgColor = widget.isDarkMode ? _darkElevated : _lightElevated;
    final borderColor = widget.isDarkMode ? _darkBorder : _lightBorder;
    final accentColor = widget.isDarkMode ? _brandBlueSoft : _brandBlue;
    final total = widget.items.length;

    Widget content = Container(
      width: double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: widget.borderRadius,
        border: widget.borderRadius != null
            ? Border.all(color: borderColor, width: 1)
            : (widget.showHorizontalBorders
                  ? Border.symmetric(
                      horizontal: BorderSide(color: borderColor, width: 1),
                    )
                  : null),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: total,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              return Center(
                child: _buildImage(widget.items[index], accentColor),
              );
            },
          ),

          if (total > 1)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF080C14).withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${_currentIndex + 1}/$total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),

          if (widget.onRemoveAt != null)
            Positioned(
              top: 10,
              right: 10,
              child: Material(
                color: const Color(0xFF080C14).withValues(alpha: 0.72),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => widget.onRemoveAt!(_currentIndex),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

          if (total > 1 && _currentIndex > 0)
            Positioned(
              left: 10,
              child: _buildArrowButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => _irAPagina(_currentIndex - 1),
              ),
            ),

          if (total > 1 && _currentIndex < total - 1)
            Positioned(
              right: 10,
              child: _buildArrowButton(
                icon: Icons.chevron_right_rounded,
                onTap: () => _irAPagina(_currentIndex + 1),
              ),
            ),

          if (total > 1)
            Positioned(
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF080C14).withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(total, (idx) {
                    final activa = idx == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: activa ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: activa
                            ? _brandBlueSoft
                            : Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: content);
    }
    return content;
  }

  Widget _buildArrowButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF0F1623).withValues(alpha: 0.78),
      shape: CircleBorder(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.18), width: 1),
      ),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 22, color: Colors.white),
        ),
      ),
    );
  }
}
