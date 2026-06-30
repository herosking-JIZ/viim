import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';

class ChauffeurHomeState {
  final bool isOnline;

  const ChauffeurHomeState({this.isOnline = false});

  ChauffeurHomeState copyWith({bool? isOnline}) =>
      ChauffeurHomeState(isOnline: isOnline ?? this.isOnline);
}

class ChauffeurHomeNotifier extends StateNotifier<ChauffeurHomeState> {
  ChauffeurHomeNotifier() : super(const ChauffeurHomeState());

  void toggleDisponibilite() {
    HapticFeedback.mediumImpact();
    state = state.copyWith(isOnline: !state.isOnline);
  }
}

final chauffeurHomeProvider =
    StateNotifierProvider<ChauffeurHomeNotifier, ChauffeurHomeState>(
  (ref) => ChauffeurHomeNotifier(),
);

// Solde portefeuille (réutilise endpoint passager)
final portefeuilleCardProvider = FutureProvider.autoDispose<double>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get<Map<String, dynamic>>('/paiement/portefeuille');
    final data = response['data'] as Map<String, dynamic>?;
    return (data?['solde'] as num?)?.toDouble() ?? 0.0;
  } catch (_) {
    return 0.0;
  }
});

// Modèle mission mockée
class MissionMock {
  final String depart;
  final String destination;
  final double distanceKm;
  final int tarif;
  int secondesRestantes;

  MissionMock({
    required this.depart,
    required this.destination,
    required this.distanceKm,
    required this.tarif,
    required this.secondesRestantes,
  });
}

// Missions mockées
final missionsMockProvider = Provider<List<MissionMock>>((ref) => [
  MissionMock(
    depart: 'Quartier Zogona',
    destination: 'Marché Central',
    distanceKm: 3.2,
    tarif: 1500,
    secondesRestantes: 25,
  ),
  MissionMock(
    depart: 'Patte d\'Oie',
    destination: 'Ouaga 2000',
    distanceKm: 5.8,
    tarif: 2500,
    secondesRestantes: 12,
  ),
]);
