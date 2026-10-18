enum WashLocationType { stationary, mobile }

enum VehicleCategory { typeA, typeB, typeC }

class ServiceItem {
  final int id;
  final String vehicleType;
  final String serviceName;
  final double stationaryPrice;
  final double mobilePrice;

  ServiceItem({
    required this.id,
    required this.vehicleType,
    required this.serviceName,
    required this.stationaryPrice,
    required this.mobilePrice,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'],
      vehicleType: json['vehicle_type'],
      serviceName: json['service_name'],
      stationaryPrice: (json['stationary_price'] as num).toDouble(),
      mobilePrice: (json['mobile_price'] as num).toDouble(),
    );
  }
}
