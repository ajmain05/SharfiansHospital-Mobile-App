/// An admin-editable translation override, as edited in the web superadmin
/// panel and returned by `GET /api/settings` -> `customTranslations`.
/// Matches `frontend/src/context/LanguageContext.jsx`'s override shape.
class CustomTranslation {
  final String key;
  final String? en;
  final String? bn;

  const CustomTranslation({required this.key, this.en, this.bn});

  factory CustomTranslation.fromJson(Map<String, dynamic> json) =>
      CustomTranslation(
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
    String s(String key, String fallback) =>
        (json[key] as String?)?.isNotEmpty == true
        ? json[key] as String
        : fallback;
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

class GalleryImage {
  final String url;
  final String title;
  final String caption;

  const GalleryImage({required this.url, this.title = '', this.caption = ''});

  factory GalleryImage.fromJson(dynamic raw) {
    if (raw is String) return GalleryImage(url: raw);
    final json = raw is Map
        ? raw.cast<String, dynamic>()
        : const <String, dynamic>{};
    return GalleryImage(
      url: _stringFrom(json, const ['url', 'imageUrl', 'src', 'secure_url']),
      title: _stringFrom(json, const ['title', 'name']),
      caption: _stringFrom(json, const ['caption', 'description']),
    );
  }
}

class FaqItem {
  final String question;
  final String answer;
  final String category;

  const FaqItem({
    required this.question,
    required this.answer,
    this.category = 'General',
  });

  factory FaqItem.fromJson(dynamic raw) {
    final json = raw is Map
        ? raw.cast<String, dynamic>()
        : const <String, dynamic>{};
    return FaqItem(
      question: _stringFrom(json, const ['question', 'q', 'title']),
      answer: _stringFrom(json, const [
        'answer',
        'a',
        'description',
        'content',
      ]),
      category: _stringFrom(json, const [
        'category',
        'group',
      ], fallback: 'General'),
    );
  }
}

class MobileAccount {
  final String provider;
  final String type;
  final String number;

  const MobileAccount({
    required this.provider,
    required this.type,
    required this.number,
  });

  factory MobileAccount.fromJson(dynamic raw) {
    final json = raw is Map
        ? raw.cast<String, dynamic>()
        : const <String, dynamic>{};
    return MobileAccount(
      provider: _stringFrom(json, const ['provider', 'name']),
      type: _stringFrom(json, const ['type', 'accountType']),
      number: _stringFrom(json, const ['number', 'phone', 'account']),
    );
  }
}

class BankDetails {
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String branchName;
  final String routingNumber;
  final String swiftCode;
  final List<MobileAccount> mobileAccounts;

  const BankDetails({
    this.bankName = '',
    this.accountName = '',
    this.accountNumber = '',
    this.branchName = '',
    this.routingNumber = '',
    this.swiftCode = '',
    this.mobileAccounts = const [],
  });

  bool get hasAny =>
      bankName.isNotEmpty ||
      accountName.isNotEmpty ||
      accountNumber.isNotEmpty ||
      branchName.isNotEmpty ||
      routingNumber.isNotEmpty ||
      swiftCode.isNotEmpty ||
      mobileAccounts.isNotEmpty;

  factory BankDetails.fallback() => const BankDetails(
        bankName: 'Islami Bank Bangladesh PLC',
        accountName: 'Sharfians Hospital Limited',
        accountNumber: '20503960100088814',
        branchName: 'Chalkbazar Branch, Chittagong',
        routingNumber: '125150833',
        swiftCode: 'IBBLBDDH',
        mobileAccounts: [],
      );

  factory BankDetails.fromJson(dynamic raw) {
    if (raw == null) return BankDetails.fallback();
    final json = raw is Map
        ? raw.cast<String, dynamic>()
        : const <String, dynamic>{};
    final accounts = <MobileAccount>[];
    final rawAccounts = json['mobileAccounts'] ?? json['mobile_accounts'] ?? json['mfs'] ?? json['mobileBanking'];
    if (rawAccounts is List) {
      accounts.addAll(
        rawAccounts
            .map(MobileAccount.fromJson)
            .where((a) => a.provider.isNotEmpty || a.number.isNotEmpty),
      );
    }

    void addLegacy(List<String> keys, String provider, String type) {
      for (final key in keys) {
        final val = json[key];
        if (val != null) {
          final str = val is Map ? (val['number'] ?? val['phone'] ?? val['account'] ?? '').toString() : val.toString();
          if (str.trim().isNotEmpty) {
            if (!accounts.any((a) => a.number == str.trim())) {
              accounts.add(MobileAccount(provider: provider, type: type, number: str.trim()));
            }
            break;
          }
        }
      }
    }

    addLegacy(const ['bkashMerchant', 'bkash_merchant'], 'bKash', 'Merchant');
    addLegacy(const ['bkashPersonal', 'bkash_personal', 'bkash', 'bkashNumber', 'bkash_number', 'bkashNo'], 'bKash', 'Personal');
    addLegacy(const ['bkashPersonal1', 'bkash_personal1'], 'bKash', 'Personal');
    addLegacy(const ['nagadPersonal', 'nagad_personal', 'nagad', 'nagadNumber', 'nagad_number', 'nagadNo'], 'Nagad', 'Personal');
    addLegacy(const ['rocketPersonal', 'rocket_personal', 'rocket', 'rocketNumber', 'rocket_number', 'rocketNo'], 'Rocket', 'Personal');
    addLegacy(const ['upayPersonal', 'upay_personal', 'upay', 'upayNumber', 'upay_number', 'upayNo'], 'Upay', 'Personal');

    final parsed = BankDetails(
      bankName: _stringFrom(json, const ['bankName', 'bank_name', 'name', 'bank', 'bankTitle', 'bank_title']),
      accountName: _stringFrom(json, const ['accountName', 'account_name', 'accountHolder', 'account_holder', 'accountTitle', 'account_title', 'title', 'holder']),
      accountNumber: _stringFrom(json, const ['accountNumber', 'account_number', 'bankAccount', 'bank_account', 'account_no', 'accountNo', 'acc_no', 'accNo', 'number']),
      branchName: _stringFrom(json, const ['branchName', 'branch_name', 'branch', 'branchAddress', 'branch_address', 'location']),
      routingNumber: _stringFrom(json, const ['routingNumber', 'routing_number', 'bankRouting', 'routing_no', 'routingNo', 'routing']),
      swiftCode: _stringFrom(json, const ['swiftCode', 'swift_code', 'swift', 'swift_no', 'swiftNo']),
      mobileAccounts: accounts,
    );

    return parsed.hasAny ? parsed : BankDetails.fallback();
  }
}

class CareerSettings {
  final bool enabled;
  final String title;
  final String titleBn;
  final String subtitle;
  final String subtitleBn;
  final String notice;
  final List<String> positions;

  const CareerSettings({
    this.enabled = true,
    this.title = 'Career',
    this.titleBn = 'ক্যারিয়ার',
    this.subtitle = 'Apply to join Sharfians Hospital.',
    this.subtitleBn = 'শরফিয়ান্স হাসপাতালের সাথে কাজ করতে আবেদন করুন।',
    this.notice = '',
    this.positions = const [],
  });

  factory CareerSettings.fromJson(dynamic raw) {
    const fb = CareerSettings();
    if (raw == false) return const CareerSettings(enabled: false);

    final json = raw is Map
        ? raw.cast<String, dynamic>()
        : const <String, dynamic>{};

    final rawPositions = json['positions'] ?? json['jobs'] ?? json['openings'];
    final positions = rawPositions is List
        ? rawPositions
              .map((p) {
                if (p is String) return p;
                if (p is Map) {
                  return _stringFrom(p.cast<String, dynamic>(), const [
                    'title',
                    'name',
                    'position',
                  ]);
                }
                return '';
              })
              .where((p) => p.trim().isNotEmpty)
              .toList()
        : const <String>[];

    final isEnabled = _boolFrom(
      json,
      const [
        'formEnabled',
        'form_enabled',
        'enabled',
        'is_open',
        'isOpen',
        'careerEnabled',
        'career_enabled',
        'isCareerOpen',
        'is_career_open',
        'active',
        'is_active',
      ],
      fallback: fb.enabled,
    );

    return CareerSettings(
      enabled: isEnabled,
      title: _stringFrom(json, const ['title'], fallback: fb.title),
      titleBn: _stringFrom(json, const [
        'title_bn',
        'titleBn',
      ], fallback: fb.titleBn),
      subtitle: _stringFrom(json, const [
        'subtitle',
        'description',
      ], fallback: fb.subtitle),
      subtitleBn: _stringFrom(json, const [
        'subtitle_bn',
        'subtitleBn',
        'description_bn',
      ], fallback: fb.subtitleBn),
      notice: _stringFrom(json, const ['notice', 'message']),
      positions: positions,
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
  final String aboutBadge;
  final String aboutBadgeBn;
  final String aboutTitle;
  final String aboutTitleBn;
  final String aboutDescription;
  final String aboutDescriptionBn;
  final String logoUrl;
  final String registerHelpText;
  final String registerHelpTextBn;
  final String loginHelpText;
  final String loginHelpTextBn;
  final String tutorialVideoUrl;
  final num minShareAmount;
  final num investmentTarget;
  final bool investorPortalEnabled;
  final List<CustomTranslation> customTranslations;
  final InvestorStatsSection investorStatsSection;
  final int totalInvestors;
  final num totalAmount;
  final List<GalleryImage> galleryImages;
  final List<FaqItem> faqs;
  final BankDetails bankDetails;
  final CareerSettings careerSettings;

  const SiteSettings({
    required this.heroTitle,
    required this.heroTitleBn,
    required this.heroSubtitle,
    required this.heroSubtitleBn,
    required this.heroDescription,
    required this.heroDescriptionBn,
    required this.badgeText,
    required this.badgeTextBn,
    required this.aboutBadge,
    required this.aboutBadgeBn,
    required this.aboutTitle,
    required this.aboutTitleBn,
    required this.aboutDescription,
    required this.aboutDescriptionBn,
    required this.logoUrl,
    required this.registerHelpText,
    required this.registerHelpTextBn,
    required this.loginHelpText,
    required this.loginHelpTextBn,
    required this.tutorialVideoUrl,
    required this.minShareAmount,
    required this.investmentTarget,
    required this.investorPortalEnabled,
    required this.customTranslations,
    required this.investorStatsSection,
    required this.totalInvestors,
    required this.totalAmount,
    required this.galleryImages,
    required this.faqs,
    required this.bankDetails,
    required this.careerSettings,
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
    aboutBadge: 'About The Project',
    aboutBadgeBn: 'প্রজেক্ট সম্পর্কে',
    aboutTitle: 'Building A Healthier Tomorrow Together',
    aboutTitleBn: 'একসাথে গড়ছি আগামীর সুস্থ ভবিষ্যৎ',
    aboutDescription:
        'Sharfians Hospital is a community-owned healthcare initiative. Through collective share investment, we are building a state-of-the-art hospital that will serve our community for generations to come.',
    aboutDescriptionBn:
        'শরফিয়ান্স হাসপাতাল একটি কমিউনিটি-মালিকানাধীন স্বাস্থ্যসেবা উদ্যোগ। সম্মিলিত শেয়ার বিনিয়োগের মাধ্যমে আমরা একটি অত্যাধুনিক হাসপাতাল নির্মাণ করছি যা আগামী প্রজন্মের সেবা করবে।',
    logoUrl: '',
    registerHelpText:
        'Note: You can login to My Portal using your registered phone number at any time to find your Investor ID and track your investments.',
    registerHelpTextBn:
        'নোট: আপনি যেকোনো সময় আপনার রেজিস্টার্ড ফোন নম্বর ব্যবহার করে My Portal-এ লগইন করে আপনার Investor ID এবং আপনার সকল বিনিয়োগের তথ্য দেখতে পারবেন।',
    loginHelpText:
        'Forgot your Investor ID? Just login using your registered phone number to find your ID on the dashboard.',
    loginHelpTextBn:
        'আপনার ইনভেস্টর আইডি ভুলে গেছেন? আপনার রেজিস্টার্ড ফোন নম্বর দিয়ে লগইন করলেই ড্যাশবোর্ডে আপনার আইডি দেখতে পাবেন।',
    tutorialVideoUrl: '',
    minShareAmount: 100000,
    investmentTarget: 1000000000,
    investorPortalEnabled: true,
    customTranslations: [],
    investorStatsSection: InvestorStatsSection(),
    totalInvestors: 0,
    totalAmount: 0,
    galleryImages: [],
    faqs: [],
    bankDetails: BankDetails(),
    careerSettings: CareerSettings(),
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
      aboutBadge: s('aboutBadge', fb.aboutBadge),
      aboutBadgeBn: s('aboutBadge_bn', fb.aboutBadgeBn),
      aboutTitle: s('aboutTitle', fb.aboutTitle),
      aboutTitleBn: s('aboutTitle_bn', fb.aboutTitleBn),
      aboutDescription: s('aboutDescription', fb.aboutDescription),
      aboutDescriptionBn: s('aboutDescription_bn', fb.aboutDescriptionBn),
      logoUrl: s('logoUrl', fb.logoUrl),
      registerHelpText: s('registerHelpText', fb.registerHelpText),
      registerHelpTextBn: s('registerHelpText_bn', fb.registerHelpTextBn),
      loginHelpText: s('loginHelpText', fb.loginHelpText),
      loginHelpTextBn: s('loginHelpText_bn', fb.loginHelpTextBn),
      tutorialVideoUrl: s('tutorialVideoUrl', fb.tutorialVideoUrl),
      minShareAmount: (json['minShareAmount'] as num?) ?? fb.minShareAmount,
      investmentTarget:
          (json['investmentTarget'] as num?) ?? fb.investmentTarget,
      investorPortalEnabled: _boolFrom(json, const ['investorPortalEnabled', 'investor_portal_enabled'], fallback: fb.investorPortalEnabled),
      customTranslations:
          (json['customTranslations'] as List?)
              ?.map(
                (e) => CustomTranslation.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          fb.customTranslations,
      investorStatsSection: InvestorStatsSection.fromJson(
        json['investorStatsSection'] as Map<String, dynamic>?,
      ),
      totalInvestors:
          (json['totalInvestors'] as num?)?.toInt() ?? fb.totalInvestors,
      totalAmount: (json['totalAmount'] as num?) ?? fb.totalAmount,
      galleryImages:
          (json['galleryImages'] as List?)
              ?.map(GalleryImage.fromJson)
              .where((i) => i.url.isNotEmpty)
              .toList() ??
          fb.galleryImages,
      faqs:
          (json['faqs'] as List?)
              ?.map(FaqItem.fromJson)
              .where((f) => f.question.isNotEmpty || f.answer.isNotEmpty)
              .toList() ??
          fb.faqs,
      bankDetails: BankDetails.fromJson(
        json['bankDetails'] ??
        json['bank_details'] ??
        json['bankAccount'] ??
        json['bank_account'] ??
        json['bankInfo'] ??
        json['bank_info'] ??
        json['paymentDetails'] ??
        json['payment_details'] ??
        json['bank'] ??
        json,
      ),
      careerSettings: CareerSettings.fromJson(
        json.containsKey('careerSettings')
            ? json['careerSettings']
            : json.containsKey('career_settings')
                ? json['career_settings']
                : json.containsKey('career')
                    ? json['career']
                    : json.containsKey('careerEnabled')
                        ? json['careerEnabled']
                        : json.containsKey('career_enabled')
                            ? json['career_enabled']
                            : json,
      ),
    );
  }
}

String _stringFrom(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value != null && value is! List && value is! Map) {
      return value.toString();
    }
  }
  return fallback;
}

bool _boolFrom(
  Map<String, dynamic> json,
  List<String> keys, {
  bool fallback = false,
}) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
  }
  return fallback;
}
