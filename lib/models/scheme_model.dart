/// Government Welfare Schemes and Eligibility Criteria Models
class SchemeModel {
  final String id;
  final String title;
  final String titleTamil;
  final String description;
  final String descriptionTamil;
  final String category; // 'Farmer', 'Citizen', 'Women', 'Health', 'Housing'
  final String benefitAmount;
  final String portalUrl;
  final int minAge;
  final int maxAge;
  final double maxIncome;
  final bool requiresLand;
  final bool requiresTnResident;
  final List<String> requiredDocuments;

  const SchemeModel({
    required this.id,
    required this.title,
    required this.titleTamil,
    required this.description,
    required this.descriptionTamil,
    required this.category,
    required this.benefitAmount,
    required this.portalUrl,
    this.minAge = 18,
    this.maxAge = 100,
    this.maxIncome = double.infinity,
    this.requiresLand = false,
    this.requiresTnResident = true,
    this.requiredDocuments = const ['Aadhaar Card', 'Ration Card', 'Bank Passbook'],
  });

  bool isEligible({
    required int userAge,
    required double userIncome,
    required double landAcres,
    required bool isTnResident,
  }) {
    if (userAge < minAge || userAge > maxAge) return false;
    if (userIncome > maxIncome) return false;
    if (requiresLand && landAcres <= 0) return false;
    if (requiresTnResident && !isTnResident) return false;
    return true;
  }
}

/// Directory of State (Tamil Nadu) and Central Schemes
class SchemeDirectory {
  static const List<SchemeModel> allSchemes = [
    SchemeModel(
      id: 's1',
      title: 'PM-KISAN Samman Nidhi',
      titleTamil: 'பிரதமர் கிசான் சம்மான் நிதி',
      description: '₹6,000 annual income support in 3 equal installments for all landholding farmers.',
      descriptionTamil: 'நிலமுள்ள விவசாயிகளுக்கு ஆண்டுக்கு ₹6,000 நிதி உதவி 3 தவணைகளில் வழங்கப்படும்.',
      category: 'Farmer',
      benefitAmount: '₹6,000 / year',
      portalUrl: 'https://pmkisan.gov.in',
      minAge: 18,
      requiresLand: true,
      requiredDocuments: ['Aadhaar Card', 'Land Patta/Chitta', 'Bank Account'],
    ),
    SchemeModel(
      id: 's2',
      title: 'Kalaignar Magalir Urimai Thittam',
      titleTamil: 'கலைஞர் மகளிர் உரிமைத் திட்டம்',
      description: 'Monthly assistance of ₹1,000 for women family heads in eligible low-income households in Tamil Nadu.',
      descriptionTamil: 'தகுதியுள்ள மகளிருக்கு மாதந்தோறும் ₹1,000 உரிமைத் தொகை வழங்கும் திட்டம்.',
      category: 'Women',
      benefitAmount: '₹1,000 / month',
      portalUrl: 'https://kmut.tn.gov.in',
      minAge: 21,
      maxAge: 65,
      maxIncome: 250000,
      requiresTnResident: true,
      requiredDocuments: ['Aadhaar Card', 'Smart Ration Card', 'Electricity Bill'],
    ),
    SchemeModel(
      id: 's3',
      title: 'TN CM Comprehensive Health Insurance (CMCHIS)',
      titleTamil: 'முதலமைச்சரின் விரிவான மருத்துவக் காப்பீட்டுத் திட்டம்',
      description: 'Cashless medical treatment up to ₹5 Lakhs per family per year across empaneled government & private hospitals.',
      descriptionTamil: 'ஆண்டுக்கு ₹5 லட்சம் வரை இலவச மருத்துவ சிகிச்சை பெற உதவும் விரிவான மருத்துவ காப்பீட்டுத் திட்டம்.',
      category: 'Health',
      benefitAmount: 'Up to ₹5,00,000 / year',
      portalUrl: 'https://www.cmchistn.com',
      minAge: 0,
      maxIncome: 120000,
      requiresTnResident: true,
      requiredDocuments: ['Smart Ration Card', 'Income Certificate', 'Aadhaar Card'],
    ),
    SchemeModel(
      id: 's4',
      title: 'PM Awas Yojana (Gramin / Urban)',
      titleTamil: 'பிரதமர் வீட்டு வசதித் திட்டம் (ஊரகம் / நகர்ப்புறம்)',
      description: 'Financial assistance up to ₹2.5 Lakhs for construction of pucca houses for homeless and kutcha house residents.',
      descriptionTamil: 'வீடற்ற மற்றும் குடிசை வீடுகளில் வசிப்போருக்கு கான்கிரீட் வீடு கட்ட ₹2.5 லட்சம் வரை நிதியுதவி.',
      category: 'Housing',
      benefitAmount: '₹2,50,000 subsidy',
      portalUrl: 'https://pmayg.nic.in',
      minAge: 21,
      maxIncome: 300000,
      requiresTnResident: false,
      requiredDocuments: ['Aadhaar Card', 'Land Deed / Patta', 'Income Certificate', 'Bank Passbook'],
    ),
    SchemeModel(
      id: 's5',
      title: 'TN Free Solar Pump Scheme',
      titleTamil: 'தமிழ்நாடு இலவச சூரியசக்தி பம்புசெட் திட்டம்',
      description: '70% capital subsidy for installing 5HP to 10HP standalone solar-powered agricultural pumps.',
      descriptionTamil: 'விவசாயிகளுக்கு 70% மானியத்தில் சூரியசக்தியால் இயங்கும் மோட்டார் பம்புசெட்டுகள் அமைத்தல்.',
      category: 'Farmer',
      benefitAmount: '70% Subsidy on Solar Pumps',
      portalUrl: 'https://aed.tn.gov.in',
      minAge: 18,
      requiresLand: true,
      requiresTnResident: true,
      requiredDocuments: ['Aadhaar Card', 'Chitta/Patta', 'Well/Borewell certificate', 'EB Non-receipt certificate'],
    ),
    SchemeModel(
      id: 's6',
      title: 'Moovalur Ramamirtham Ammaiyar Pudhumai Penn Scheme',
      titleTamil: 'புதுமைப் பெண் திட்டம்',
      description: '₹1,000 monthly financial aid for female students from government schools pursuing higher education.',
      descriptionTamil: 'அரசுப் பள்ளிகளில் படித்து உயர்கல்வி பயிலும் மாணவிகளுக்கு மாதம் ₹1,000 நிதியுதவி.',
      category: 'Women',
      benefitAmount: '₹1,000 / month',
      portalUrl: 'https://penkalvi.tn.gov.in',
      minAge: 17,
      maxAge: 25,
      requiresTnResident: true,
      requiredDocuments: ['School Bonafide Certificate', 'Aadhaar Card', 'College ID Card', 'Bank Passbook'],
    ),
  ];
}
