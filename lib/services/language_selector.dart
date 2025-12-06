import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_app/pages/home/profile_page/widgets/feature_item.dart';

// Color palette
const Color primaryYellow = Color(0xFFCFC000);
const Color secondaryRed = Color(0xFFC63232);
const Color accentYellow = Color(0xFFFFD600);
const Color black = Color(0xFF000000);
const Color white = Color(0xFFFFFFFF);
const Color greyBg = Color(0xFFF8F8F8);
const Color greyText = Color(0xFF666666);
const Color lightGrey = Color(0xFFF0F0F0);
const Color selectedColor = Color(0xFFE8F5E9);
const Color selectedBorder = Color(0xFF4CAF50);

class LanguageSelector {
  static FeatureItem build(BuildContext context) {
    final currentLocale = context.locale;

    return FeatureItem(
      icon: Icons.language_rounded,
      title: 'Language',
      subtitle: _getLanguageName(currentLocale),
      onTap: () => _showLanguageDialog(context),
    );
  }

  static String _getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'ar':
        return 'العربية';
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      default:
        return 'English';
    }
  }

  static void _showLanguageDialog(BuildContext context) {
    final currentLocale = context.locale;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryYellow, accentYellow],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Language',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: black,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Language Options
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLanguageOption(
                      'العربية',
                      'Arabic',
                      const Locale('ar'),
                      currentLocale,
                      context,
                    ),
                    const SizedBox(height: 12),
                    _buildLanguageOption(
                      'English',
                      'English',
                      const Locale('en'),
                      currentLocale,
                      context,
                    ),
                    const SizedBox(height: 12),
                    _buildLanguageOption(
                      'Français',
                      'French',
                      const Locale('fr'),
                      currentLocale,
                      context,
                    ),
                    const SizedBox(height: 24),
                    
                    // Info Text
                    Text(
                      'App will restart to apply language changes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: greyText,
                        fontStyle: FontStyle.italic,
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

  static Widget _buildLanguageOption(
    String languageName,
    String englishName,
    Locale locale,
    Locale currentLocale,
    BuildContext context,
  ) {
    final isSelected = currentLocale.languageCode == locale.languageCode;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? selectedColor : lightGrey,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(
                color: selectedBorder,
                width: 1.5,
              )
            : null,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? selectedBorder.withOpacity(0.2) : white,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _getFlagEmoji(locale.languageCode),
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              languageName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: black,
              ),
            ),
            Text(
              englishName,
              style: TextStyle(
                fontSize: 14,
                color: greyText,
              ),
            ),
          ],
        ),
        trailing: isSelected
            ? Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: secondaryRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: white,
                  size: 18,
                ),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        onTap: () async {
          await _changeLanguage(context, locale, languageName);
        },
      ),
    );
  }

  static String _getFlagEmoji(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return '🇲🇦'; // Morocco flag for Arabic
      case 'en':
        return '🇺🇸'; // US flag for English
      case 'fr':
        return '🇫🇷'; // France flag for French
      default:
        return '🌐'; // Globe for unknown
    }
  }

  static Future<void> _changeLanguage(
    BuildContext context,
    Locale locale,
    String languageName,
  ) async {
    try {
      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('locale', locale.languageCode);
      
      // Change app locale
      await context.setLocale(locale);
      
      // Show success message
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Language changed to $languageName',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: selectedBorder,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to change language: ${e.toString()}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: secondaryRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}