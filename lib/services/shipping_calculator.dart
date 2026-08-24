class ShippingCalculator {
  static String getRegion(int postcode) {
    if (postcode >= 1000 && postcode <= 2800) return 'west_remote';
    if (postcode >= 4000 && postcode <= 8999) return 'west_inner';
    if (postcode >= 10000 && postcode <= 14999) return 'west_outer';
    if (postcode >= 15000 && postcode <= 18500) return 'west_remote';
    if (postcode >= 20000 && postcode <= 24300) return 'west_remote';
    if (postcode >= 25000 && postcode <= 28800) return 'west_remote';
    if (postcode >= 30000 && postcode <= 49999) return 'west_outer';
    if (postcode >= 39000 && postcode <= 39200) return 'west_remote';
    if (postcode == 49000 || postcode == 69000) return 'west_remote';
    if (postcode >= 87000 && postcode <= 87033) return 'east_labuan';
    if (postcode >= 88000 && postcode <= 92999) return 'east_sabah';
    if (postcode >= 93000 && postcode <= 99999) return 'east_sarawak';
    return 'west_outer';
  }

  static bool isWestRemote(int postcode) {
    return (postcode >= 1000 && postcode <= 2800) ||
           (postcode >= 15000 && postcode <= 18500) ||
           (postcode >= 20000 && postcode <= 24300) ||
           (postcode >= 25000 && postcode <= 28800) ||
           (postcode >= 39000 && postcode <= 39200) ||
           postcode == 49000 || postcode == 69000;
  }

  static Map<String, dynamic> calculateAir({
    required double length, required double width, required double height,
    required double weight, required int boxes, required int postcode,
    required String goodsType,
  }) {
    final volumeWeight = (length * width * height) / 6000 * boxes;
    final totalWeight = weight * boxes;
    double chargeWeight = volumeWeight > totalWeight ? (totalWeight + volumeWeight) / 2 : totalWeight;
    chargeWeight = chargeWeight < 11 ? 11 : chargeWeight;
    double unitPrice = goodsType == 'normal' ? 20.5 : goodsType == 'battery' ? 29.0 : 30.0;
    final totalCost = chargeWeight * unitPrice;
    return {
      'method': '✈️ 空运DDP', 'chargeWeight': chargeWeight.toStringAsFixed(2),
      'unitPrice': unitPrice, 'totalCost': totalCost.toStringAsFixed(2),
    };
  }

  static Map<String, dynamic> calculateSeaBulk({
    required double length, required double width, required double height,
    required double weight, required int boxes, required int postcode,
    required String goodsType,
  }) {
    final volume = (length * width * height) / 1000000 * boxes;
    final totalWeight = weight * boxes;
    final region = getRegion(postcode);
    final isHeavy = totalWeight / volume > 500;
    double finalVolume = isHeavy ? totalWeight / 500 : volume;
    double unitPrice = region.startsWith('west') ? 670.0 : 980.0;
    if (goodsType == 'sensitive') unitPrice += 20;
    if (finalVolume < 0.3) finalVolume = 0.3;
    finalVolume = region.startsWith('west') ? (finalVolume * 100).ceil() / 100 : (finalVolume * 10).ceil() / 10;
    final totalCost = finalVolume * unitPrice;
    double delivery = 0;
    if (isWestRemote(postcode)) delivery = finalVolume.ceil() * 80;
    return {
      'method': '🚢 海运大货', 'finalVolume': finalVolume.toStringAsFixed(2),
      'unitPrice': unitPrice, 'totalCost': totalCost.toStringAsFixed(2),
      'deliveryFee': delivery.toStringAsFixed(2), 'isHeavy': isHeavy,
    };
  }

  static Map<String, dynamic> calculateSeaParcel({
    required double length, required double width, required double height,
    required double weight, required int boxes, required int postcode,
    required String goodsType,
  }) {
    final volumeWeight = (length * width * height) / 6000 * boxes;
    final totalWeight = weight * boxes;
    final region = getRegion(postcode);
    double chargeWeight = [totalWeight, volumeWeight, 11.0].reduce((a, b) => a > b ? a : b);
    final unitPrice = region.startsWith('west') ? 5.5 : 10.0;
    final totalCost = chargeWeight * unitPrice;
    return {
      'method': '📦 海运小包', 'chargeWeight': chargeWeight.toStringAsFixed(2),
      'unitPrice': unitPrice, 'finalCost': totalCost.toStringAsFixed(2),
    };
  }
}
