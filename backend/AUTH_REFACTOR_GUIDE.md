# Authentication Refactoring Guide

## Overview

This document describes the comprehensive refactoring of N'DJIGI's authentication system to ensure atomic user creation, proper role synchronization, and Keycloak as the single source of truth for credentials.

**Completed Phases:** All 6 phases complete as of 2026-05-20

## Architecture Principles

### 1. Keycloak is Source of Truth for Credentials

- **Credentials** (passwords, authentication): Stored and managed only in Keycloak
- **Roles**: Defined in Keycloak as realm roles (`ndjigi-admin`, `ndjigi-gestionnaire`, etc.)
- **PostgreSQL**: Stores business data and references to Keycloak users via `keycloak_id`

### 2. Atomic User Creation

All user creation flows use `userProvisioningService.create()`:

```
1. Create user in Keycloak → get keycloak_id
2. Create user in PostgreSQL with keycloak_id reference
3. If PostgreSQL fails → rollback Keycloak user deletion
4. If rollback fails → emit ROLLBACK_FAILED (manual cleanup required)
```

This ensures: **Either user exists in both systems, or neither.**

### 3. Middleware Syncs Roles from Token

- Extract `realm_access.roles` from Keycloak token
- Convert realm roles to local roles: `ndjigi-admin` → `admin`
- Use local roles for authorization (not database roles)
- Do NOT default to `'passager'` if roles empty (user has no role assignment)

### 4. Password Lifecycle

1. **Provisioning**: Temp password generated, set in Keycloak
2. **First Connection**: User accepts invitation, sets password
   - Password synced to Keycloak via `resetPassword()` API
   - Password hashed and stored locally (audit trail, non-blocking)
3. **Ongoing**: Only Keycloak validates passwords (via login flow)

## Key Files

### Core Services

| File | Purpose |
|------|---------|
| `src/services/userProvisioningService.js` | Atomic user creation (Phase 1) |
| `src/errors/ProvisioningError.js` | Typed error handling |
| `src/constants/roles.js` | Role mapping utilities |

### Middlewares

| File | Purpose |
|------|---------|
| `src/middlewares/keycloakAuth.js` | Validate token, sync roles, auto-provision (Phase 2) |
| `src/middlewares/authenticateKeycloak.js` | Additional auth checks, role sync (Phase 2) |

### Controllers

| File | Purpose | Change |
|------|---------|--------|
| `src/controllers/utilisateurController.js` | User creation endpoint | Now uses userProvisioningService (Phase 3) |
| `src/services/gestionnaireService.js` | Gestionnaire creation | Now uses userProvisioningService (Phase 3) |
| `src/controllers/invitationController.js` | First connection (password set) | Syncs password to Keycloak (Phase 4) |

### Seeds & Utilities

| File | Purpose | Change |
|------|---------|--------|
| `prisma/seed.js` | Dev seed data | Now uses userProvisioningService (Phase 5) |
| `prisma/wipe-users-dev.js` | Delete seeded users | NEW in Phase 5 |

### Tests

| File | Tests | Count |
|------|-------|-------|
| `__tests__/userProvisioningService.integration.test.js` | Role mapping, password generation | 7 |
| `__tests__/middleware.keycloak.test.js` | Role sync from tokens | 19 |
| `__tests__/auth-refactor.e2e.test.js` | Full lifecycle scenarios | 15 |

## Phase-by-Phase Changes

### Phase 1: Create userProvisioningService ✅

**Goal**: Atomic user creation across Keycloak and PostgreSQL

**Files**:
- `src/services/userProvisioningService.js` (NEW)
- `src/errors/ProvisioningError.js` (NEW)
- `src/constants/roles.js` (NEW)

**Implementation**:
```javascript
const newUser = await userProvisioningService.create({
  email: 'user@example.com',
  nom: 'Dupont',
  prenom: 'Jean',
  role: 'gestionnaire',
  numero_telephone: '+22670123456',
  adresse: '123 Rue Test',
  metadata: { id_parking: 'parking-uuid' },
  sendInvitationEmail: true,
  createdBy: { id_utilisateur: 'admin-uuid', role: 'admin' }
});
```

**Error Codes**:
- `EMAIL_EXISTS`: Email already in use
- `INVALID_ROLE`: Invalid role parameter
- `KEYCLOAK_ERROR`: Keycloak user creation failed
- `PG_ERROR`: PostgreSQL error
- `ROLLBACK_FAILED`: Cannot cleanup after failure

### Phase 2: Refactor Middlewares for Role Sync ✅

**Goal**: Extract and sync roles from Keycloak tokens

**Changes**:
- `keycloakAuth.js`: Use `getLocalRole()` for conversion, remove fallback to `'passager'`
- `authenticateKeycloak.js`: Convert realm roles instead of merging with DB roles

**Before**:
```javascript
// WRONG: Mixing incompatible role formats
const roles = [...new Set([...keycloakRealmRoles, ...dbRoles])];
// Result: ['ndjigi-admin', 'passager', 'chauffeur'] ← mixed formats!
```

**After**:
```javascript
// RIGHT: Convert to consistent local role format
const roles = keycloakRealmRoles
  .map(kcRole => getLocalRole(kcRole))
  .filter(role => role !== null);
// Result: ['admin'] ← consistent local roles
```

### Phase 3: Migrate User Creation Controllers ✅

**Goal**: Consolidate all user creation to use userProvisioningService

**Files Changed**:
- `src/controllers/utilisateurController.js`: 280 LOC → 70 LOC
- `src/services/gestionnaireService.js`: 170 LOC → 50 LOC

**Key Change**:
```javascript
// Old: Manual Keycloak + PG operations
const kcUser = await keycloakService.adminAPI.users.create(...);
const pgUser = await prisma.utilisateur.create(...);

// New: Single atomic call
const user = await userProvisioningService.create({...});
```

### Phase 4: Sync Password to Keycloak on Activation ✅

**Goal**: Ensure password set during first connection syncs to Keycloak

**File**: `src/controllers/invitationController.js`

**Three-step process**:
```javascript
// 1. Sync password to Keycloak (source of truth)
await keycloakService.adminAPI.users.resetPassword({
  realm: process.env.KEYCLOAK_REALM,
  id: user.keycloak_id,
  credential: {
    temporary: false,
    type: 'password',
    value: nouveau_mot_de_passe
  }
});

// 2. Hash and store locally (audit/fallback)
const hashedPassword = await bcrypt.hash(nouveau_mot_de_passe, 10);

// 3. Update PostgreSQL (clear invitation token, mark activated)
await tx.utilisateur.update({...});
```

**Non-blocking**: If Keycloak sync fails, local password still works (user can use Keycloak reset-password flow)

### Phase 5: Refactor Seeds & Add Wipe Utility ✅

**Goal**: Use atomic userProvisioningService for seed data

**Files**:
- `prisma/seed.js`: Refactored to use userProvisioningService
- `prisma/wipe-users-dev.js`: NEW utility for dev cleanup

**Seed Usage**:
```javascript
await userProvisioningService.create({
  email: 'test@example.com',
  nom: 'Test',
  prenom: 'User',
  role: 'passager',
  numero_telephone: '+22670000001',
  systemUser: true,  // Skip Keycloak (dev/test)
  sendInvitationEmail: false
});
```

**Wipe Usage**:
```bash
# Delete all seeded test users (development only)
node prisma/wipe-users-dev.js
```

### Phase 6: E2E Tests & Documentation ✅

**Goal**: Validate entire refactoring and document architecture

**Files**:
- `__tests__/auth-refactor.e2e.test.js`: 15 scenario tests
- `AUTH_REFACTOR_GUIDE.md`: This file

**Test Coverage**:
- User provisioning atomicity
- Role sync from tokens
- Password lifecycle
- Error handling and rollback
- Architecture principles
- Backward compatibility

## User Flows

### Normal User Provisioning

```
Admin → utilisateurController.create()
  ↓
userProvisioningService.create()
  ├─ Create in Keycloak (get keycloak_id)
  ├─ Create in PostgreSQL with keycloak_id
  ├─ Create role-specific records
  ├─ Create portefeuille
  └─ Send invitation email (non-blocking)
  ↓
User receives email with temp password
```

### User Login & Role Sync

```
User → POST /auth/login with credentials
  ↓
Keycloak validates password, returns token with realm_access.roles
  ↓
keycloakAuth or authenticateKeycloak middleware
  ├─ Verify token (JWKS)
  ├─ Extract realm_access.roles
  ├─ Convert to local roles via getLocalRole()
  └─ Attach to req.user.roles
  ↓
Controller receives req.user with synced roles from token
```

### First Connection (Password Set)

```
User → POST /auth/complete-first-connection with new password
  ↓
invitationController.completeFirstConnection()
  ├─ Validate invitation token
  ├─ Sync password to Keycloak (keycloakService.adminAPI.users.resetPassword)
  ├─ Hash and store locally
  ├─ Clear invitation token
  └─ Mark account activated
  ↓
User can now login with Keycloak password
```

## Error Scenarios

### Email Already Exists

```
userProvisioningService detects email in PostgreSQL
  → ProvisioningError('EMAIL_EXISTS')
  → Controller returns 409 Conflict
```

### Keycloak Failure During Provisioning

```
User created in Keycloak ✓
PostgreSQL fails ✗
  → Keycloak user deleted (rollback) ✓
  → ProvisioningError('PG_ERROR')
```

### Keycloak Failure During Rollback (Critical)

```
User created in Keycloak ✓
PostgreSQL fails ✗
Keycloak deletion fails ✗
  → ProvisioningError('ROLLBACK_FAILED')
  → Log: Manual cleanup required
  → Alert ops team
```

## Development Workflows

### Running Seeds

```bash
# Populate database with test data
npx prisma db seed

# Or with npm script
npm run seed
```

### Cleaning Up Seeds

```bash
# Delete all seeded test users (safe for dev only)
node prisma/wipe-users-dev.js
```

### Running Tests

```bash
# All tests
npm test

# Specific test suites
npm test -- __tests__/auth-refactor.e2e.test.js
npm test -- __tests__/middleware.keycloak.test.js
npm test -- __tests__/userProvisioningService.integration.test.js
```

## Migration & Backward Compatibility

### Handling Legacy Users (No keycloak_id)

During migration, some users may not have `keycloak_id`:
- Middleware handles `null` keycloak_id gracefully
- `invitationController` checks `if (user.keycloak_id)` before syncing password
- Non-blocking: If no keycloak_id, local password stored instead
- Can manually migrate users or create new ones via userProvisioningService

### System Users

For automation and testing:
```javascript
await userProvisioningService.create({
  email: 'system@ndjigi.local',
  role: 'admin',
  systemUser: true,  // Skip Keycloak
  sendInvitationEmail: false
});
// Results in keycloak_id = 'SYSTEM_NO_AUTH'
```

## Security Guarantees

1. **Atomicity**: User exists in both Keycloak and PostgreSQL, or neither
2. **Role Source of Truth**: Token roles used for authorization, never DB roles
3. **Password Security**: Only stored in Keycloak for normal users
4. **Audit Trail**: All provisioning operations logged as structured JSON
5. **Cascade Safety**: Deletes cascade properly (avis → documents → satellites → roles → user)

## Monitoring & Logging

All operations logged as structured JSON:

```json
{
  "event": "user_provisioning_success",
  "email": "user@example.com",
  "id_utilisateur": "uuid",
  "keycloak_id": "uuid",
  "role": "gestionnaire",
  "timestamp": "2026-05-20T12:00:00Z"
}
```

Key events:
- `user_provisioning_start`, `_success`, `_error`
- `keycloak_user_created`, `keycloak_user_created_error`
- `pg_user_created`, `pg_error`
- `keycloak_password_reset`, `keycloak_password_reset_failed`
- `rollback_failed_manual_cleanup_required` (CRITICAL)

## Testing Strategy

### Layer 1: Unit Tests (26 tests)
- Role mapping (`getLocalRole`, `getKeycloakRole`)
- Password generation
- ProvisioningError class
- Middleware role conversion logic

### Layer 2: Integration Tests
- OTP flow, TOTP setup, password reset
- Full endpoint testing with mocks
- Error handling scenarios

### Layer 3: End-to-End Tests (15 scenarios)
- Complete user lifecycle
- Role synchronization
- Password sync
- Error handling and rollback
- Architecture properties
- Security guarantees

## Checklist for Production Deployment

- [ ] All tests passing (26 unit + 15 e2e)
- [ ] Database migrations applied
- [ ] Keycloak realm configured with `ndjigi-*` roles
- [ ] Environment variables set: `KEYCLOAK_REALM`, `KEYCLOAK_URL`, `KEYCLOAK_CLIENT_ID`, `KEYCLOAK_CLIENT_SECRET`
- [ ] Admin client credentials configured in Keycloak
- [ ] Email service configured for invitations
- [ ] Logging aggregation set up (monitor for `ROLLBACK_FAILED`)
- [ ] Ops team trained on manual cleanup procedure
- [ ] Audit logs exported and backed up
- [ ] User migration plan for legacy users (if applicable)

## References

- Phase 1 commit: `3e60796` - Create userProvisioningService
- Phase 2 commit: `08838ed` - Sync roles from Keycloak tokens
- Phase 3 commit: `0eb1232` - Migrate controllers to userProvisioningService
- Phase 4 commit: `9a374fe` - Sync password to Keycloak on activation
- Phase 5 commit: `433867e` - Refactor seeds and add wipe utility
- Phase 6 commit: (this document and e2e tests)

## Support & Troubleshooting

### Issue: User created in Keycloak but not PostgreSQL

**Solution**: Ops must manually delete the Keycloak user to avoid orphaned record
```bash
# In Keycloak Admin Console
Realm → Users → Find user → Delete
```

### Issue: Password won't sync to Keycloak on first connection

**Check**:
- Keycloak admin API credentials correct
- User has valid keycloak_id (not SYSTEM_NO_AUTH)
- Network connectivity to Keycloak

**Action**:
- Check logs for `keycloak_password_reset_failed`
- User can manually trigger Keycloak password reset flow
- Email service can resend invitation if needed

### Issue: User has no roles after login

**Causes**:
- Keycloak token has empty `realm_access.roles`
- User not assigned realm role in Keycloak

**Action**:
- Assign `ndjigi-*` realm role in Keycloak Admin Console
- User logs out and logs back in (token refreshed)

## Questions?

Contact the platform team for questions about this refactoring.
