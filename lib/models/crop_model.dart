/// Crop and Farmer Marketplace Models
class CropItem {
  final String name;
  final double currentPrice;
  final double predictedPrice;
  final String demand; // 'High', 'Medium', 'Low'
  final List<double> history;

  CropItem(
    this.name,
    this.currentPrice,
    this.predictedPrice,
    this.demand, {
    this.history = const [],
  });

  double get priceDiff => predictedPrice - currentPrice;
  double get priceDiffPercent =>
      currentPrice > 0 ? (priceDiff / currentPrice) * 100 : 0.0;
  bool get isBullish => predictedPrice >= currentPrice;
}

class CropListing {
  final String id;
  final String farmerId;
  final String farmerName;
  final String farmerPhone;
  final String crop;
  final double pricePerKg;
  final double quantityKg;
  final String location;
  final DateTime createdAt;

  CropListing({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    this.farmerPhone = '',
    required this.crop,
    required this.pricePerKg,
    required this.quantityKg,
    required this.location,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'farmerId': farmerId,
    'farmerName': farmerName,
    'farmerPhone': farmerPhone,
    'crop': crop,
    'pricePerKg': pricePerKg,
    'quantityKg': quantityKg,
    'location': location,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CropListing.fromMap(Map<String, dynamic> map) {
    return CropListing(
      id: map['id'] as String? ?? '',
      farmerId: map['farmerId'] as String? ?? '',
      farmerName: map['farmerName'] as String? ?? '',
      farmerPhone: map['farmerPhone'] as String? ?? '',
      crop: map['crop'] as String? ?? '',
      pricePerKg: (map['pricePerKg'] as num?)?.toDouble() ?? 0.0,
      quantityKg: (map['quantityKg'] as num?)?.toDouble() ?? 0.0,
      location: map['location'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class FarmerCooperative {
  final String id;
  final String wardId;
  final String crop;
  final List<String> farmerIds;
  final List<String> farmerNames;
  final double totalWeightKg;
  String status; // 'Open', 'Full', 'Dispatched'

  FarmerCooperative({
    required this.id,
    required this.wardId,
    required this.crop,
    required this.farmerIds,
    required this.farmerNames,
    required this.totalWeightKg,
    this.status = 'Open',
  });
}

class PollOption {
  final String label;
  int votes;
  PollOption(this.label, {this.votes = 0});
}
