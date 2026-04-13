class EstimateFareUseCase {
  // Ces valeurs viendraient normalement d'un appel API vers zone_tarifaire
  double execute({
    required double distanceKm,
    required double basePrice,
    required double pricePerKm,
  }) {
    // Calcul simplifié pour le MVP
    return basePrice + (distanceKm * pricePerKm);
  }
}