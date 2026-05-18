# 📋 Identifiants des Utilisateurs Créés - N'DJIGI

**Date de création:** 2026-05-18  
**Status:** ✅ Configuration complète  

---

## 👤 Utilisateurs Existants

### 1️⃣ Administrateur Principal

| Propriété | Valeur |
|-----------|--------|
| **Username** | `admin` |
| **Email** | `admin@ndjigi.test` |
| **Password** | `Admin@12345` |
| **Rôles** | `admin`, `ndjigi-admin` |
| **Status** | ✅ Actif |
| **Email Vérifié** | ✅ Oui |

**Accès :**
- ✅ Dashboard Admin (http://localhost:3000/dashboard)
- ✅ Création de gestionnaires
- ✅ Gestion des parkings

---

## 🔐 Keycloak Admin Credentials

Pour accéder à la console d'administration Keycloak :

| Propriété | Valeur |
|-----------|--------|
| **URL** | `http://localhost:8080/admin` |
| **Username** | `admin` |
| **Password** | `admin` |
| **Realm** | `ndjigi` |

---

## 📝 Notes Importantes

### Création d'Utilisateurs Additionnels

Pour créer de nouveaux utilisateurs (gestionnaires, etc.), utilisez l'endpoint API :

```bash
POST /api/v1/utilisateurs
Content-Type: application/json
Authorization: Bearer <admin-token>

{
  "email": "gestionnaire@example.com",
  "firstName": "Jean",
  "lastName": "Manager",
  "role": "gestionnaire",
  "parking_id": 1
}
```

### Réinitialisation de Mot de Passe

1. Allez à : `http://localhost:8080/admin`
2. Connectez-vous avec `admin/admin`
3. Allez à **Users > admin**
4. Onglet **Credentials**
5. Cliquez sur **Set Password**
6. Entrez le nouveau mot de passe

### Convention de Nommage

- **Email test:** `{role}@ndjigi.test` (ex: `gestionnaire@ndjigi.test`)
- **Mot de passe par défaut:** Conforme à la politique de sécurité
  - Minimum 8 caractères
  - Au moins une majuscule
  - Au moins un chiffre
  - Au moins un caractère spécial

---

## 🔄 Rôles Disponibles

| Rôle | Description | Accès Web |
|------|-------------|-----------|
| `admin` | Administrateur système | ✅ Oui |
| `ndjigi-admin` | Admin N'DJIGI | ✅ Oui |
| `gestionnaire` | Gestionnaire de parking | ✅ Oui |
| `chauffeur` | Chauffeur | ❌ Non (app mobile uniquement) |
| `passager` | Passager | ❌ Non (app mobile uniquement) |
| `proprietaire` | Propriétaire de véhicule | ❌ Non (app mobile uniquement) |

---

## 🧪 Test Rapide

Pour tester la connexion :

1. Allez à : `http://localhost:3000/login`
2. Entrez les identifiants
3. Vous recevrez un code SMS (test: `611699`)
4. Entrez le code pour accéder au dashboard

---

## ⚠️ Sécurité

- ✅ Mots de passe sécurisés en production
- ✅ Tokens JWT courts (15 min)
- ✅ Refresh tokens dans les cookies
- ✅ HTTPS obligatoire en production
- ⚠️ Changez tous les mots de passe par défaut avant la production

---

## 📞 Dépannage

**Problème:** Connexion échouée
- Vérifiez que Keycloak est en cours d'exécution
- Vérifiez les variables d'environnement KEYCLOAK_*
- Vérifiez les logs du backend

**Problème:** Mot de passe oublié
- Réinitialisez via Keycloak Admin Console
- Utilisez l'endpoint de réinitialisation de mot de passe

**Problème:** Code SMS invalide
- En développement, utilisez: `611699`
- Vérifiez l'email pour le SMS réel

---

**Dernière mise à jour:** 2026-05-18  
**Développé par:** Claude Haiku 4.5
