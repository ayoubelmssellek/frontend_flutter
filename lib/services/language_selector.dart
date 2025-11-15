import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_app/pages/home/profile_page/widgets/feature_item.dart';

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
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('العربية', const Locale('ar'), currentLocale, context),
            _buildLanguageOption('English', const Locale('en'), currentLocale, context),
            _buildLanguageOption('Français', const Locale('fr'), currentLocale, context),
          ],
        ),
      ),
    );
  }

  static Widget _buildLanguageOption(
      String languageName, Locale locale, Locale currentLocale, BuildContext context) {
    final isSelected = currentLocale.languageCode == locale.languageCode;

    return ListTile(
      title: Text(languageName),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.deepOrange) : null,
      onTap: () async {
        await context.setLocale(locale);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('locale', locale.languageCode);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Language changed to $languageName'),
            backgroundColor: Colors.deepOrange,
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }
}
