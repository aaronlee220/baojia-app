class ShippingCalculator {
  // 默认费率（和网页版完全一致）
  static const Map<String, double> defaultRates = {
    'airNormal': 20.5,
    'airBattery': 29,
    'airSensitive': 30,
    'seaWestInnerNormal': 650,
    'seaWestInnerSensitive': 670,
    'seaWestOuterNormal': 670,
    'seaWestOuterSensitive': 690,
    'seaEastNormal': 980,
    'seaEastSensitive': 1080,
    'parcelWest': 5.5,
    'parcelEast': 10,
    'exchangeRate': 1.64,
  };

  // 区域判断（和网页版完全一致）
  static String getRegion(int postcode) {
    if (postcode >= 1000 && postcode <= 2800) return 'west_remote';
    if (postcode >= 4000 && postcode <= 8999) return 'west_inner';
    if (postcode >= 10000 && postcode <= 14999) return 'west_outer';
    if (postcode >= 15000 && postcode <= 18500) return 'west_remote';
    if (postcode >= 20000 && postcode <= 28800) return 'west_remote';
    if (postcode >= 30000 && postcode <= 49999) return 'west_outer';
    if (postcode >= 39000 && postcode <= 39200) return 'west_remote';
    if (postcode == 49000 || postcode == 69000) return 'west_remote';
    if (postcode >= 87000 && postcode <= 87033) return 'east_labuan';
    if (postcode >= 88000 && postcode <= 92999) return 'east_sabah';
    if (postcode >= 93000 && postcode <= 99999) return 'east_sarawak';
    return 'west_outer';
  }

  // 西马偏远判定（和网页版完全一致）
  static bool isWestRemote(int postcode) {
    return (postcode >= 1000 && postcode <= 2800) ||
           (postcode >= 15000 && postcode <= 18500) ||
           (postcode >= 20000 && postcode <= 24300) ||
           (postcode >= 25000 && postcode <= 28800) ||
           (postcode >= 39000 && postcode <= 39200) ||
           postcode == 49000 ||
           postcode == 69000;
  }

  // 海运小包偏远判定（和网页版完全一致）
  static bool isParcelRemote(int postcode) {
    return (postcode >= 87000 && postcode <= 87033) ||
           (postcode >= 98700 && postcode <= 98859);
  }

  // 空运计算（和网页版完全一致）
  static Map<String, dynamic> calculateAir({
    required double length, required double width, required double height,
    required double weight, required int boxes, required int postcode,
    required String goodsType, Map<String, double>? rates,
  }) {
    final r = rates ?? defaultRates;
    final volW = (length * width * height) / 6000 * boxes;
    final totW = weight * boxes;
    double cw = volW > totW ? (totW + volW) / 2 : totW;
    cw = cw < 11 ? 11 : cw;

    double up;
    if (goodsType == 'normal') up = r['airNormal']!;
    else if (goodsType == 'battery') up = r['airBattery']!;
    else up = r['airSensitive']!;

    final totalCost = cw * up;
    return {
      'totalCost': totalCost.toStringAsFixed(2),
      'chargeWeight': cw.toStringAsFixed(2),
      'unitPrice': up,
    };
  }

  // 海运大货计算（和网页版完全一致）
  static Map<String, dynamic> calculateSeaBulk({
    required double length, required double width, required double height,
    required double weight, required int boxes, required int postcode,
    required String goodsType, Map<String, double>? rates,
  }) {
    final r = rates ?? defaultRates;
    final vol = (length * width * height) / 1000000 * boxes;
    final totW = weight * boxes;
    final region = getRegion(postcode);
    final isS = goodsType == 'sensitive';

    double up;
    double minCBM;
    if (region == 'west_inner') {
      up = isS ? r['seaWestInnerSensitive']! : r['seaWestInnerNormal']!;
      minCBM = 0.3;
    } else if (region == 'west_outer' || region == 'west_remote') {
      up = isS ? r['seaWestOuterSensitive']! : r['seaWestOuterNormal']!;
      minCBM = 0.3;
    } else {
      up = isS ? r['seaEastSensitive']! : r['seaEastNormal']!;
      minCBM = 0.5;
    }

    double fv = totW / 500 > vol ? totW / 500 : vol;
    if (fv < minCBM) fv = minCBM;
    fv = region.startsWith('west') ? (fv * 100).ceil() / 100 : (fv * 10).ceil() / 10;

    double delivery = 0;
    // 西马偏远
    if (isWestRemote(postcode)) {
      final cb = fv.ceil();
      delivery = cb * 80;
    }
    // 沙巴/纳闽派件费
    if (region == 'east_sabah' || region == 'east_labuan') {
      final pc = postcode;
      final cb = fv.ceil();
      if (pc >= 88500 && pc <= 88799) delivery = cb * 100;
      else if (pc >= 88800 && pc <= 89999) delivery = cb * 200;
      else if (pc >= 90000 && pc <= 90999) delivery = cb * 240;
      else if (pc >= 91000 && pc <= 91399) delivery = cb * 300;
      else if (pc >= 91400 && pc <= 91999) delivery = cb * 260;
      else if (region == 'east_labuan') delivery = cb * 240 + 100;
      else if (pc >= 88000 && pc <= 88499) delivery = 0;
      else delivery = cb * 200;
    }
    // 砂拉越派件费
    if (region == 'east_sarawak') {
      final pc = postcode;
      final cb = fv.ceil();
      if (pc >= 96000 && pc <= 96999) delivery = 0;
      else if (pc >= 93000 && pc <= 93999) delivery = cb * 100;
      else if (pc >= 94000 && pc <= 94999) delivery = cb * 100;
      else if (pc >= 97000 && pc <= 97999) delivery = cb * 100;
      else if (pc >= 98000 && pc <= 98499) delivery = cb * 150;
      else if (pc >= 98500 && pc <= 98699) delivery = cb * 150;
      else if (pc >= 96400 && pc <= 96599) delivery = cb * 180;
      else if (pc >= 98300 && pc <= 98399) delivery = cb * 180;
      else if (pc >= 95000 && pc <= 95999) delivery = cb * 200;
      else delivery = cb * 100;
    }

    final totalCost = fv * up;
    final isHeavy = totW / 500 > vol;

    return {
      'totalCost': totalCost.toStringAsFixed(2),
      'deliveryFee': delivery.toStringAsFixed(2),
      'finalVolume': fv.toStringAsFixed(2),
      'unitPrice': up,
      'isHeavy': isHeavy,
      'heavyRatio': (totW / fv).toStringAsFixed(1),
      'note': delivery > 0 ? '含偏远/派件费 ¥$delivery' : '',
    };
  }

  // 海运小包计算（和网页版完全一致）
  static Map<String, dynamic> calculateSeaParcel({
    required double length, required double width, required double height,
    required double weight, required int boxes, required int postcode,
    required String goodsType, Map<String, double>? rates,
  }) {
    final r = rates ?? defaultRates;
    final volW = (length * width * height) / 6000 * boxes;
    final totW = weight * boxes;
    final region = getRegion(postcode);
    double cw = [totW, volW, 11.0].reduce((a, b) => a > b ? a : b);

    final up = region.startsWith('west') ? r['parcelWest']! : r['parcelEast']!;
    double cost = cw * up;

    // 偏远费（纳闽岛/林梦/老越）
    if (isParcelRemote(postcode)) {
      cost += 20 + (cw.ceil() - 1) * 15;
    }

    return {
      'finalCost': cost.toStringAsFixed(2),
      'chargeWeight': cw.toStringAsFixed(2),
      'unitPrice': up,
    };
  }
}
