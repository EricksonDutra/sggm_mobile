import 'package:flutter/material.dart';

class AppTheme {
  // ✅ Verde Oficial da Igreja Presbiteriana do Brasil
  static const Color presbyterianoVerde = Color(0xFF006747);
  static const Color presbyterianoVerdeClaro = Color(0xFF00854D);
  static const Color presbyterianoVerdeEscuro = Color(0xFF004D2F);

  // ✅ Cores do sistema
  static const Color backgroundPrincipal = Color(0xFF121212);
  static const Color backgroundSecundario = Color(0xFF1E1E1E);
  static const Color backgroundTerciario = Color(0xFF2A2A2A);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // ✅ Cores primárias com verde IPB
      primaryColor: presbyterianoVerde,
      primaryColorLight: presbyterianoVerdeClaro,
      primaryColorDark: presbyterianoVerdeEscuro,

      colorScheme: const ColorScheme.dark(
        primary: presbyterianoVerde,
        primaryContainer: presbyterianoVerdeEscuro,
        secondary: presbyterianoVerdeClaro,
        secondaryContainer: Color(0xFF003D28),
        surface: backgroundSecundario,
        error: Color(0xFFCF6679),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.black,
      ),

      scaffoldBackgroundColor: backgroundPrincipal,

      // ✅ AppBar
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: backgroundSecundario,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        shape: Border(
          bottom: BorderSide(
            color: presbyterianoVerde,
            width: 2,
          ),
        ),
      ),

      // ✅ Cards
      cardTheme: CardThemeData(
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: backgroundSecundario,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),

      // ✅ Inputs
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: presbyterianoVerde, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCF6679)),
        ),
        filled: true,
        fillColor: backgroundTerciario,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: const TextStyle(
          color: Color(0xFFB0B0B0),
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF757575),
          fontSize: 14,
        ),
      ),

      // ✅ Botões elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: presbyterianoVerde,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: presbyterianoVerde.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // ✅ Botões de texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: presbyterianoVerdeClaro,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // ✅ Botões outlined
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: presbyterianoVerde,
          side: const BorderSide(color: presbyterianoVerde, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      // ✅ FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: presbyterianoVerde,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ✅ BottomNavigationBar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundSecundario,
        selectedItemColor: presbyterianoVerdeClaro,
        unselectedItemColor: Color(0xFF757575),
        selectedIconTheme: IconThemeData(size: 28),
        unselectedIconTheme: IconThemeData(size: 24),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),

      // ✅ Drawer
      drawerTheme: const DrawerThemeData(
        backgroundColor: backgroundSecundario,
        elevation: 16,
      ),

      // ✅ ListTile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        selectedTileColor: presbyterianoVerde.withOpacity(0.15),
        selectedColor: presbyterianoVerdeClaro,
      ),

      // ✅ Divider
      dividerTheme: const DividerThemeData(
        color: Color(0xFF424242),
        thickness: 1,
        space: 1,
      ),

      // ✅ Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return presbyterianoVerde;
          }
          return const Color(0xFF616161);
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // ✅ Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return presbyterianoVerde;
          }
          return const Color(0xFF616161);
        }),
      ),

      // ✅ Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return presbyterianoVerdeClaro;
          }
          return const Color(0xFFBDBDBD);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return presbyterianoVerde.withOpacity(0.5);
          }
          return const Color(0xFF616161);
        }),
      ),

      // ✅ Slider
      sliderTheme: const SliderThemeData(
        activeTrackColor: presbyterianoVerde,
        inactiveTrackColor: Color(0xFF616161),
        thumbColor: presbyterianoVerdeClaro,
        overlayColor: Color(0x33006747),
      ),

      // ✅ Progress indicators
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: presbyterianoVerde,
        circularTrackColor: Color(0xFF424242),
      ),

      // ✅ SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: backgroundTerciario,
        contentTextStyle: const TextStyle(color: Colors.white),
        actionTextColor: presbyterianoVerdeClaro,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 6,
      ),

      // ✅ Dialog - CORRIGIDO
      dialogTheme: DialogThemeData(
        backgroundColor: backgroundSecundario,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: Color(0xFFE0E0E0),
          fontSize: 16,
        ),
      ),

      // ✅ Chip
      chipTheme: ChipThemeData(
        backgroundColor: backgroundTerciario,
        selectedColor: presbyterianoVerde,
        secondarySelectedColor: presbyterianoVerdeClaro,
        labelStyle: const TextStyle(color: Colors.white),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // ✅ TabBar - CORRIGIDO
      tabBarTheme: const TabBarThemeData(
        labelColor: presbyterianoVerdeClaro,
        unselectedLabelColor: Color(0xFF9E9E9E),
        indicatorColor: presbyterianoVerde,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ✅ Icon theme
      iconTheme: const IconThemeData(
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
