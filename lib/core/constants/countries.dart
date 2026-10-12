class DealCountry {
  final String nameAr;
  final String nameEn;
  final String code;
  final String flag;
  final String phoneCode;
  final String currencyCode;
  final String currencyAr;

  const DealCountry({
    required this.nameAr,
    required this.nameEn,
    required this.code,
    required this.flag,
    required this.phoneCode,
    required this.currencyCode,
    required this.currencyAr,
  });
}

class DealCountries {
  DealCountries._();

  static const String defaultCountryCode = 'QA';

  static const List<DealCountry> items = [
    DealCountry(
      nameAr: 'قطر',
      nameEn: 'Qatar',
      code: 'QA',
      flag: '🇶🇦',
      phoneCode: '+974',
      currencyCode: 'QAR',
      currencyAr: 'ريال قطري',
    ),
     DealCountry(
      nameAr: 'السودان',
      nameEn: 'Sudan',
      code: 'SD',
      flag: '🇸🇩',
      phoneCode: '+249',
      currencyCode: 'SDG',
      currencyAr: 'جنيه سوداني',
    ),
    DealCountry(
      nameAr: 'مصر',
      nameEn: 'Egypt',
      code: 'EG',
      flag: '🇪🇬',
      phoneCode: '+20',
      currencyCode: 'EGP',
      currencyAr: 'جنيه مصري',
    ),
    DealCountry(
      nameAr: 'السعودية',
      nameEn: 'Saudi Arabia',
      code: 'SA',
      flag: '🇸🇦',
      phoneCode: '+966',
      currencyCode: 'SAR',
      currencyAr: 'ريال سعودي',
    ),
    DealCountry(
      nameAr: 'الإمارات',
      nameEn: 'United Arab Emirates',
      code: 'AE',
      flag: '🇦🇪',
      phoneCode: '+971',
      currencyCode: 'AED',
      currencyAr: 'درهم إماراتي',
    ),
    DealCountry(
      nameAr: 'الكويت',
      nameEn: 'Kuwait',
      code: 'KW',
      flag: '🇰🇼',
      phoneCode: '+965',
      currencyCode: 'KWD',
      currencyAr: 'دينار كويتي',
    ),
    DealCountry(
      nameAr: 'البحرين',
      nameEn: 'Bahrain',
      code: 'BH',
      flag: '🇧🇭',
      phoneCode: '+973',
      currencyCode: 'BHD',
      currencyAr: 'دينار بحريني',
    ),
    DealCountry(
      nameAr: 'عُمان',
      nameEn: 'Oman',
      code: 'OM',
      flag: '🇴🇲',
      phoneCode: '+968',
      currencyCode: 'OMR',
      currencyAr: 'ريال عُماني',
    ),
     DealCountry(
      nameAr: 'أمريكا',
      nameEn: 'America',
      code: 'US',
      flag: '🇺🇸',
      phoneCode: '+1',
      currencyCode: 'USD',
      currencyAr: 'دولار أمريكي',
    ),
    DealCountry(
      nameAr: 'أثيوبيا',
      nameEn: 'Ethiopia',
      code: 'ET',
      flag: '🇪🇹',
      phoneCode: '+251',
      currencyCode: 'ETB',
      currencyAr: 'بير أثيوبي',
    ),
    DealCountry(
      nameAr: 'رواندا',
      nameEn: 'Rwanda',
      code: 'RW',
      flag: '🇷🇼',
      phoneCode: '+250',
      currencyCode: 'RWF',
      currencyAr: 'فرنك رواندي',
    ),
  ];

  static DealCountry byCode(String code) {
    return items.firstWhere(
      (country) => country.code == code,
      orElse: () => items.first,
    );
  }
}