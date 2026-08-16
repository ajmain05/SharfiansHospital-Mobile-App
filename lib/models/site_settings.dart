/// An admin-editable translation override, as edited in the web superadmin
/// panel and returned by `GET /api/settings` -> `customTranslations`.
/// Matches `frontend/src/context/LanguageContext.jsx`'s override shape.
class CustomTranslation {
  final String key;
  final String? en;
  final String? bn;

  const CustomTranslation({required this.key, this.en, this.bn});

  factory CustomTranslation.fromJson(Map<String, dynamic> json) => CustomTranslation(
        key: (json['key'] as String?) ?? '',
        en: json['en'] as String?,
        bn: json['bn'] as String?,
      );

  String? forLang(String lang) => lang == 'bn' ? bn : en;
}

class InvestorStatsSection {
  final bool enabled;
  final String title;
  final String titleBn;
  final String subtitle;
  final String subtitleBn;
  final String investorLabel;
  final String investorLabelBn;
  final String amountLabel;
  final String amountLabelBn;

  const InvestorStatsSection({
    this.enabled = true,
    this.title = 'Growing Together',
    this.titleBn = 'একসাথে বাড়ছি',
    this.subtitle = 'Real-time snapshot of our investor community',
    this.subtitleBn = 'আমাদের বিনিয়োগকারী সম্প্রদায়ের তাৎক্ষণিক চিত্র',
    this.investorLabel = 'Total Investors',
    this.investorLabelBn = 'মোট বিনিয়োগকারী',
    this.amountLabel = 'Committed Amount',
    this.amountLabelBn = 'মোট বিনিয়োগ',
  });

  factory InvestorStatsSection.fromJson(Map<String, dynamic>? json) {
    const fb = InvestorStatsSection();
    if (json == null) return fb;
    String s(String key, String fallback) => (json[key] as String?)?.isNotEmpty == true ? json[key] as String : fallback;
    return InvestorStatsSection(
      enabled: json['enabled'] as bool? ?? fb.enabled,
      title: s('title', fb.title),
      titleBn: s('title_bn', fb.titleBn),
      subtitle: s('subtitle', fb.subtitle),
      subtitleBn: s('subtitle_bn', fb.subtitleBn),
      investorLabel: s('investorLabel', fb.investorLabel),
      investorLabelBn: s('investorLabel_bn', fb.investorLabelBn),
      amountLabel: s('amountLabel', fb.amountLabel),
      amountLabelBn: s('amountLabel_bn', fb.amountLabelBn),
    );
  }
}

/// Mirrors `frontend/src/services/siteService.js`'s `_fallbackSettings` +
/// `getSiteSettings()` merge behavior: known fields are typed here for the
/// screens Phase 1 needs (home, registration, login); later phases add
/// getters for faqs/galleryImages/bankDetails/careerSettings the same way,
/// without needing to touch this class's shape.
class SiteSettings {
  final String heroTitle;
  final String heroTitleBn;
  final String heroSubtitle;
  final String heroSubtitleBn;
  final String heroDescription;
  final String heroDescriptionBn;
  final String badgeText;
  final String badgeTextBn;
  final String logoUrl;
  final String registerHelpText;
  final String registerHelpTextBn;
  final String loginHelpText;
  final String loginHelpTextBn;
  final num minShareAmount;
  final num investmentTarget;
  final bool investorPortalEnabled;
  final List<CustomTranslation> customTranslations;
  final InvestorStatsSection investorStatsSection;
  final int totalInvestors;
  final num totalAmount;

  const SiteSettings({
    required this.heroTitle,
    required this.heroTitleBn,
    required this.heroSubtitle,
    required this.heroSubtitleBn,
    required this.heroDescription,
    required this.heroDescriptionBn,
    required this.badgeText,
    required this.badgeTextBn,
    required this.logoUrl,
    required this.registerHelpText,
    required this.registerHelpTextBn,
    required this.loginHelpText,
    required this.loginHelpTextBn,
    required this.minShareAmount,
    required this.investmentTarget,
    required this.investorPortalEnabled,
    required this.customTranslations,
    required this.investorStatsSection,
    required this.totalInvestors,
    required this.totalAmount,
  });

  factory SiteSettings.fallback() => const SiteSettings(
        heroTitle: 'Sharfians Hospital',
        heroTitleBn: 'শরফিয়ান্স হাসপাতাল',
        heroSubtitle: 'Share Management System',
        heroSubtitleBn: 'শেয়ার ম্যানেজমেন্ট সিস্টেম',
        heroDescription:
            'Join our community-driven healthcare revolution. Invest in our hospital project and help us deliver quality medical services to every citizen.',
        heroDescriptionBn:
            'আমাদের কমিউনিটি-চালিত স্বাস্থ্যসেবা বিপ্লবে যোগ দিন। আমাদের হাসপাতাল প্রকল্পে বিনিয়োগ করুন এবং প্রতিটি নাগরিকের জন্য মানসম্মত চিকিৎসা সেবা নিশ্চিত করতে সাহায্য করুন।',
        badgeText: 'Community Healthcare Investment Programme',
        badgeTextBn: 'কমিউনিটি হেলথকেয়ার ইনভেস্টমেন্ট প্রোগ্রাম',
        logoUrl: '',
        registerHelpText:
            'Note: You can login to My Portal using your registered phone number at any time to find your Investor ID and track your investments.',
        registerHelpTextBn:
            'নোট: আপনি যেকোনো সময় আপনার রেজিস্টার্ড ফোন নম্বর ব্যবহার করে My Portal-এ লগইন করে আপনার Investor ID এবং আপনার সকল বিনিয়োগের তথ্য দেখতে পারবেন।',
        loginHelpText:
            'Forgot your Investor ID? Just login using your registered phone number to find your ID on the dashboard.',
        loginHelpTextBn:
            'আপনার ইনভেস্টর আইডি ভুলে গেছেন? আপনার রেজিস্টার্ড ফোন নম্বর দিয়ে লগইন করলেই ড্যাশবোর্ডে আপনার আইডি দেখতে পাবেন।',
        minShareAmount: 100000,
        investmentTarget: 1000000000,
        investorPortalEnabled: true,
        customTranslations: [],
        investorStatsSection: InvestorStatsSection(),
        totalInvestors: 0,
        totalAmount: 0,
      );

  factory SiteSettings.fromJson(Map<String, dynamic> json) {
    final fb = SiteSettings.fallback();
    String s(String key, String fallback) {
      final v = json[key];
      if (v is String && v.trim().isNotEmpty) return v;
      return fallback;
    }

    return SiteSettings(
      heroTitle: s('heroTitle', fb.heroTitle),
      heroTitleBn: s('heroTitle_bn', fb.heroTitleBn),
      heroSubtitle: s('heroSubtitle', fb.heroSubtitle),
      heroSubtitleBn: s('heroSubtitle_bn', fb.heroSubtitleBn),
      heroDescription: s('heroDescription', fb.heroDescription),
      heroDescriptionBn: s('heroDescription_bn', fb.heroDescriptionBn),
      badgeText: s('badgeText', fb.badgeText),
      badgeTextBn: s('badgeText_bn', fb.badgeTextBn),
      logoUrl: s('logoUrl', fb.logoUrl),
      registerHelpText: s('registerHelpText', fb.registerHelpText),
      registerHelpTextBn: s('registerHelpText_bn', fb.registerHelpTextBn),
      loginHelpText: s('loginHelpText', fb.loginHelpText),
      loginHelpTextBn: s('loginHelpText_bn', fb.loginHelpTextBn),
      minShareAmount: (json['minShareAmount'] as num?) ?? fb.minShareAmount,
      investmentTarget: (json['investmentTarget'] as num?) ?? fb.investmentTarget,
      investorPortalEnabled: json['investorPortalEnabled'] as bool? ?? fb.investorPortalEnabled,
      customTranslations: (json['customTranslations'] as List?)
              ?.map((e) => CustomTranslation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          fb.customTranslations,
      investorStatsSection: InvestorStatsSection.fromJson(json['investorStatsSection'] as Map<String, dynamic>?),
      totalInvestors: (json['totalInvestors'] as num?)?.toInt() ?? fb.totalInvestors,
      totalAmount: (json['totalAmount'] as num?) ?? fb.totalAmount,
    );
  }
}
