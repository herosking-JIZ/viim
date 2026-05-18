// ═══════════════════════════════════════════════════════════════
// CONTRAT API — Types TypeScript alignés sur le backend N'DJIGI
// Basé sur la réponse réelle : { success, message, data, errors }
// ═══════════════════════════════════════════════════════════════

// ─── Enveloppe standard de toutes les réponses ───────────────
export interface ApiResponse<T = unknown> {
  success: boolean
  message: string
  data: T
  errors?: Record<string, string> | null
}

// ─── Réponse paginée standard ─────────────────────────────────
export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  limit: number
  totalPages: number
}

// ═══════════════════════════════════════════════════════════════
// AUTH
// ═══════════════════════════════════════════════════════════════

export type UserRole =
  | 'admin'
  | 'gestionnaire'   // ← rôle parkeur dans votre backend
  | 'chauffeur'
  | 'passager'
  | 'proprietaire'
  | 'super_admin'

export type AccountStatus = 'actif' | 'suspendu' | 'en_attente' | 'banni' | 'supprime'

// Rôle d'un utilisateur (relation utilisateur_role)
export interface UtilisateurRole {
  id_utilisateur: string
  role: UserRole
  actif: boolean
  date_activation: string
  date_desactivation: string | null
}

// Objet user tel que renvoyé par le backend dans data.user
export interface BackendUser {
  id_utilisateur: string
  numero_telephone: string
  email: string
  nom: string
  prenom: string
  photo_profil: string | null
  adresse: string | null
  tentatives_connexion: number
  bloque_jusqu_au: string | null
  date_inscription: string
  statut_compte: AccountStatus
  auth_provider: string
  note_moyenne: number | null
  deux_fa_activee: boolean
  supprime_le: string | null
  utilisateur_role: UtilisateurRole[]
}

// Tokens renvoyés par le backend
export interface BackendTokens {
  accessToken: string
  refreshToken: string
}

// data de la réponse de login
export interface LoginResponseData {
  user: BackendUser
  permissions: string[]
  tokens: BackendTokens
}

// Réponse Keycloak login (Phase 1+)
export interface KeycloakLoginResponse {
  access_token: string
  refresh_token: string
  expires_in: number
  token_type: string
  user: {
    id_utilisateur: string
    keycloak_id: string
    email: string
    nom: string
    prenom: string
    numero_telephone: string
    photo_profil: string | null
    roles: UserRole[]
    auth_provider: string
  }
}

// Ce que le frontend stocke en mémoire/localStorage pour l'utilisateur connecté
export interface AuthUser {
  id_utilisateur: string
  email: string
  nom: string
  prenom: string
  numero_telephone: string
  photo_profil: string | null
  // Rôle principal déduit (admin, gestionnaire, etc.)
  role: UserRole
  // Rôles complets
  roles: UserRole[]
  // Permissions accordées par le backend
  permissions: string[]
  // parking_id si gestionnaire (récupéré depuis le profil)
  parking_id?: string
}

export interface LoginCredentials {
  email: string
  mot_de_passe: string
}

// ═══════════════════════════════════════════════════════════════
// UTILISATEURS
// ═══════════════════════════════════════════════════════════════


export interface Utilisateur {
  id_utilisateur: string
  nom: string
  prenom: string
  email: string
  numero_telephone: string
  adresse?: string | null
  statut_compte: AccountStatus
  date_inscription: string
  photo_profil?: string | null
  note_moyenne?: number | null
  roles: UserRole[]
  // parking_id si gestionnaire
  parking_id?: string | null
}

// Payload pour créer un utilisateur (admin uniquement)
export interface CreateUserPayload {
  nom: string
  prenom: string
  email: string
  numero_telephone: string
  mot_de_passe: string
  role: UserRole
  adresse?: string
  // Si role = gestionnaire, on peut associer un parking
  parking_id?: string
}

// ═══════════════════════════════════════════════════════════════
// DOCUMENTS
// ═══════════════════════════════════════════════════════════════

export type DocumentType = 'permis' | 'cni' | 'carte_grise' | 'assurance'
export type DocumentStatus = 'en_attente' | 'valide' | 'rejete'

export interface Document {
  id_document: string
  id_utilisateur: string
  utilisateur_nom: string
  utilisateur_prenom: string
  type: DocumentType
  url_fichier: string
  statut_verification: DocumentStatus
  date_soumission: string
  date_expiration?: string | null
  motif_rejet?: string | null
}

// ═══════════════════════════════════════════════════════════════
// TRAJETS
// ═══════════════════════════════════════════════════════════════

export type TrajetStatut = 'en_attente' | 'en_cours' | 'termine' | 'annule'

export interface Trajet {
  id_trajet: string
  passager_nom: string
  chauffeur_nom: string
  adresse_depart: string
  adresse_arrivee: string
  distance_km?: number | null
  duree_estimee_min?: number | null
  tarif_final?: number | null
  methode_paiement?: string | null
  statut: TrajetStatut
  date_heure_debut?: string | null
  date_heure_fin?: string | null
  type_trajet: string
}

// ═══════════════════════════════════════════════════════════════
// FINANCES / WALLET
// ═══════════════════════════════════════════════════════════════

export type TransactionType = 'course' | 'location' | 'commission' | 'remboursement' | 'depot' | 'retrait'
export type TransactionStatut = 'complete' | 'en_attente' | 'echec'

export interface Transaction {
  id_paiement: string
  description: string
  type: TransactionType
  montant: number
  statut: TransactionStatut
  date_paiement: string
  id_utilisateur: string
}

export interface FinanceKpis {
  commissions_totales: number
  volume_courses: number
  remboursements: number
  taux_commission: number
  // Wallet plateforme
  solde_wallet_plateforme?: number
}

// Wallet d'un utilisateur
export interface Wallet {
  id_portefeuille: string
  id_utilisateur: string
  solde: number
  dette_commission: number
  devise: string
  statut: string
}

// Payload pour faire un dépôt admin → passager
export interface DepotPayload {
  id_utilisateur: string
  montant: number
  description?: string
}

// ═══════════════════════════════════════════════════════════════
// PARKING
// ═══════════════════════════════════════════════════════════════

export type EtatVehicule = 'bon' | 'a_verifier' | 'dommage'
export type TypeMouvement = 'entree' | 'sortie'

export interface Parking {
  id_parking: string
  nom: string
  adresse: string
  ville: string
  capacite_totale: number
  capacite_occupee: number
  horaires?: string | null
  actif: boolean
  latitude?: number | null
  longitude?: number | null
}

export interface VehiculeParking {
  id_vehicule: string
  immatriculation: string
  marque: string
  modele: string
  categorie: string
  proprietaire_nom: string
  statut: 'disponible' | 'en_location' | 'maintenance'
  etat: EtatVehicule
}

export interface MouvementParking {
  id_log: string
  id_vehicule: string
  immatriculation: string
  id_parking: string
  parking_nom: string
  parkeur_nom: string
  type_mouvement: TypeMouvement
  etat_vehicule: EtatVehicule
  date_mouvement: string
  commentaire?: string | null
}

// ═══════════════════════════════════════════════════════════════
// SUPPORT / TICKETS
// ═══════════════════════════════════════════════════════════════

export type TicketStatut = 'ouvert' | 'en_cours' | 'resolu' | 'ferme'
export type TicketPriorite = 'faible' | 'normale' | 'haute' | 'urgente'

export interface Ticket {
  id_ticket: string
  id_utilisateur: string
  utilisateur_nom: string
  utilisateur_prenom: string
  sujet: string
  description: string
  statut: TicketStatut
  priorite: TicketPriorite
  date_creation: string
  date_resolution?: string | null
  // Si lié à un trajet ou une transaction
  id_trajet?: string | null
  id_paiement?: string | null
  // true si le ticket est éligible à un remboursement
  eligible_remboursement?: boolean
}

// ═══════════════════════════════════════════════════════════════
// CONFIGURATION
// ═══════════════════════════════════════════════════════════════
export interface ZoneTarifaire {
  id_zone: string
  nom: string
  vitesse_moyenne_kmh: number
  coefficient_max: number
  actif: boolean
}

export interface CategorieVehicule {
  id_categorie: string
  nom: string
  description: string
  actif: boolean
}

export interface TarifCategorieZone {
  id_zone: string
  id_categorie: string
  tarif_base: number
  tarif_km: number
  tarif_minute: number
  actif: boolean
  // relations hydratées par le backend pour affichage
  zone?: ZoneTarifaire
  categorie?: CategorieVehicule
}


export interface CodePromo {
  id_promo: string
  code: string
  type_reduction: 'fixe' | 'pourcentage'
  valeur: number
  date_debut: string
  date_fin?: string | null
  nb_utilisations_max?: number | null
  nb_utilisations_actuel: number
  actif: boolean
}

// ═══════════════════════════════════════════════════════════════
// DASHBOARD
// ═══════════════════════════════════════════════════════════════

export interface AdminKpis {
  total_utilisateurs: number
  courses_aujourd_hui: number
  revenus_commission_jour: number
  satisfaction_moyenne: number
  tendance_utilisateurs: number
  tendance_courses: number
}

export interface ChartDataPoint {
  label: string
  value: number
}

export interface TopChauffeur {
  rang: number
  nom: string
  chiffre_affaires: number
}



