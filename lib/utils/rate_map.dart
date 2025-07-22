class RateMapping {
  static const Map<String, double> rateMap = {
    'UNUSABLE': 0.0,
    'TERRIBLE': 0.5,
    'VERY_POOR': 1.0,
    'POOR': 1.5,
    'BELOW_AVERAGE': 2.0,
    'FAIR': 2.5,
    'AVERAGE': 3.0,
    'ABOVE_AVERAGE': 3.5,
    'GOOD': 4.0,
    'VERY_GOOD': 4.5,
    'EXCELLENT': 5.0,
  };

  static final Map<double, String> valueToEnum = {
    0.0: 'UNUSABLE',
    0.5: 'TERRIBLE',
    1.0: 'VERY_POOR',
    1.5: 'POOR',
    2.0: 'BELOW_AVERAGE',
    2.5: 'FAIR',
    3.0: 'AVERAGE',
    3.5: 'ABOVE_AVERAGE',
    4.0: 'GOOD',
    4.5: 'VERY_GOOD',
    5.0: 'EXCELLENT',
  };

  static double getRateValue(dynamic rate) {
    if (rate == null) return 0.0;

    if (rate is num) return rate.toDouble();

    if (rate is String) {
      return rateMap[rate.toUpperCase()] ?? 0.0;
    }

    return 0.0;
  }

  static String getRateString(double value) {
    return valueToEnum[value] ?? 'UNUSABLE';
  }

  static int getStarsFromValue(double value) {
    if (value == 0.0) return 1; // UNUSABLE -> 1 estrela
    if (value == 0.5) return 1; // TERRIBLE -> 1 estrela
    if (value == 1.0) return 1; // VERY_POOR -> 1 estrela
    if (value == 1.5) return 2; // POOR -> 2 estrelas
    if (value == 2.0) return 2; // BELOW_AVERAGE -> 2 estrelas
    if (value == 2.5) return 3; // FAIR -> 3 estrelas
    if (value == 3.0) return 3; // AVERAGE -> 3 estrelas
    if (value == 3.5) return 4; // ABOVE_AVERAGE -> 4 estrelas
    if (value == 4.0) return 4; // GOOD -> 4 estrelas
    if (value == 4.5) return 5; // VERY_GOOD -> 5 estrelas
    if (value == 5.0) return 5; // EXCELLENT -> 5 estrelas

    return 1;
  }

  static double getValueFromStars(int stars) {
    switch (stars) {
      case 1:
        return 1.0; // VERY_POOR
      case 2:
        return 2.0; // BELOW_AVERAGE
      case 3:
        return 3.0; // AVERAGE
      case 4:
        return 4.0; // GOOD
      case 5:
        return 5.0; // EXCELLENT
      default:
        return 1.0;
    }
  }

  static String getEnumFromStars(int stars) {
    double value = getValueFromStars(stars);
    return getRateString(value);
  }

  static String getReadableRate(String rateString) {
    switch (rateString.toUpperCase()) {
      case 'UNUSABLE':
        return 'Inutilizável';
      case 'TERRIBLE':
        return 'Terrível';
      case 'VERY_POOR':
        return 'Muito Ruim';
      case 'POOR':
        return 'Ruim';
      case 'BELOW_AVERAGE':
        return 'Abaixo da Média';
      case 'FAIR':
        return 'Regular';
      case 'AVERAGE':
        return 'Médio';
      case 'ABOVE_AVERAGE':
        return 'Acima da Média';
      case 'GOOD':
        return 'Bom';
      case 'VERY_GOOD':
        return 'Muito Bom';
      case 'EXCELLENT':
        return 'Excelente';
      default:
        return 'Não Avaliado';
    }
  }
}
