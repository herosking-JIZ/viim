# ⚡ Quick Test Checklist - Temporary Password Strategy

**Tester:** ________________  
**Date:** 2026-05-19  
**Status:** À remplir

---

## 🧪 Test Execution Checklist

### Prerequisites
- [ ] Backend running (`docker compose logs backend` = no errors)
- [ ] Frontend running (`npm run dev` in web/n-djigi)
- [ ] Admin logged in
- [ ] Database accessible

---

## Test 1: Create Gestionnaire
- [ ] Navigate to `/admin/gestionnaires` → Click "Créer"
- [ ] Fill form:
  - [ ] Prénom: Jean
  - [ ] Nom: Dupont
  - [ ] Email: test1@example.fr
  - [ ] Téléphone: +226 70000001
  - [ ] Parking: Select one
- [ ] Submit form
- [ ] **Expected:** ✅ Success page, message "Identifiants temporaires envoyés"
- [ ] **Verify:** Email received with `Gestionnaire@XXXX` format

**Error Handling:**
- [ ] Email already exists → 409 error message displayed
- [ ] Phone already exists → 409 error message displayed
- [ ] Parking not found → 400 error message displayed

---

## Test 2: Email Uniqueness
- [ ] Create Gestionnaire 2:
  - [ ] Email: test2@example.fr
  - [ ] Copy password from email 1: `Gestionnaire@????`
  - [ ] Copy password from email 2: `Gestionnaire@????`
- [ ] **Expected:** Passwords are DIFFERENT (not same digits)
- [ ] Verify DB:
  ```sql
  SELECT email, MOD(CAST(SUBSTR(mot_de_passe_hash, 1, 10) AS INTEGER), 10000) as last_4_digits 
  FROM utilisateur WHERE email IN ('test1@example.fr', 'test2@example.fr');
  ```
  - [ ] Two different passwords in DB

---

## Test 3: Login → Redirect to Change Password
- [ ] Open `/login`
- [ ] Enter:
  - [ ] Email: test1@example.fr
  - [ ] Password: `Gestionnaire@XXXX` (from email)
- [ ] Click "Connexion"
- [ ] **Expected:** 
  - [ ] Page redirects to `/auth/change-password`
  - [ ] NOT to dashboard
- [ ] **Verify:** Page title = "Changer le mot de passe"

---

## Test 4: Dashboard Access Blocked (403)
- [ ] Try to navigate to `/dashboard` directly (URL bar)
- [ ] **Expected:**
  - [ ] 403 Forbidden error
  - [ ] Redirects back to `/auth/change-password`
  - [ ] Message: "Vous devez changer votre mot de passe..."

---

## Test 5: Change Password Success
- [ ] On `/auth/change-password` page
- [ ] Fill form:
  - [ ] Ancien mot de passe: `Gestionnaire@XXXX`
  - [ ] Nouveau mot de passe: `SecurePass@123456`
  - [ ] Confirmer: `SecurePass@123456`
- [ ] Click "Mettre à jour"
- [ ] **Expected:**
  - [ ] ✅ Message: "Mot de passe changé avec succès"
  - [ ] Toast: "Mot de passe modifié"
  - [ ] Redirects to dashboard
  - [ ] Can access dashboard content

---

## Test 6: Reconnect with New Password
- [ ] Logout (or delete tokens from localStorage)
- [ ] Go to `/login`
- [ ] Enter:
  - [ ] Email: test1@example.fr
  - [ ] Password: `SecurePass@123456`
- [ ] Click "Connexion"
- [ ] **Expected:**
  - [ ] ✅ Direct access to dashboard (NO redirect to change password)
  - [ ] Full app access

---

## Test 7: Password Validation Strict

### 7a: Too short (< 12 chars)
- [ ] Old password: `Gestionnaire@XXXX`
- [ ] New: `Short@123`
- [ ] **Expected:** ❌ Error message displayed

### 7b: No uppercase
- [ ] New: `newpassword@123`
- [ ] **Expected:** ❌ Error "majuscule requise"

### 7c: No lowercase
- [ ] New: `NEWPASSWORD@123`
- [ ] **Expected:** ❌ Error "minuscule requise"

### 7d: No digit
- [ ] New: `NewPassword@!`
- [ ] **Expected:** ❌ Error "chiffre requis"

### 7e: No special char
- [ ] New: `NewPassword123`
- [ ] **Expected:** ❌ Error "caractère spécial"

### 7f: Wrong old password
- [ ] Old: `WrongPassword`
- [ ] New: `Valid@Password123`
- [ ] **Expected:** ❌ Error 401 "Mot de passe actuel incorrect"

---

## Test 8: Different Passwords Per Gestionnaire
- [ ] Email 1 password: `Gestionnaire@AAAA`
- [ ] Email 2 password: `Gestionnaire@BBBB`
- [ ] **Expected:** ✅ AAAA ≠ BBBB
- [ ] Login as test1: works with `Gestionnaire@AAAA`
- [ ] Logout, login as test2: works with `Gestionnaire@BBBB`
- [ ] Try test1 with `Gestionnaire@BBBB`: ❌ Login fails

---

## Test 9: Post-Change Access
- [ ] After changing password (Test 5, 6):
- [ ] Try to access `/auth/change-password` again
- [ ] **Expected:** Either:
  - [ ] A. Page loads (can change password again)
  - [ ] B. Redirects to `/profil/mot-de-passe` (alternative route)
  - [ ] Clarify expected behavior: ________________

---

## 🔍 Backend Verification

### Logs Check
```bash
docker compose logs backend | tail -50
```
- [ ] No ERROR lines
- [ ] No passwords logged in CLEAR TEXT
- [ ] [GESTIONNAIRE_CREATED] log present
- [ ] [PASSWORD_CHANGED] log present

### Database Check
```bash
docker exec ndjigi-postgres psql -U ndjigi_user -d ndjigi_db
```

**Check schema:**
```sql
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name='utilisateur' 
AND column_name IN ('mot_de_passe_temporaire', 'invitation_token');
```
- [ ] `mot_de_passe_temporaire` exists (type: boolean)
- [ ] `invitation_token` does NOT exist

**Check data:**
```sql
SELECT email, mot_de_passe_temporaire FROM utilisateur 
WHERE email IN ('test1@example.fr', 'test2@example.fr');
```
- [ ] test1: `mot_de_passe_temporaire` = false (after change)
- [ ] test2: `mot_de_passe_temporaire` = true (if not changed)

```sql
SELECT COUNT(*) as orphaned_invitation_rows FROM utilisateur 
WHERE invitation_token IS NOT NULL;
```
- [ ] Result = 0 (no leftover invitation data)

---

## ⚡ Performance Check
- [ ] Login request: < 2s ✅
- [ ] Change password request: < 2s ✅
- [ ] Dashboard load: < 3s ✅
- [ ] No console errors during navigation ✅

---

## 🔒 Security Spot Checks

### Check API Response (DevTools Network tab)
- [ ] Login response: NO `tempPassword` or `password` field
- [ ] Only in email: password visible in plaintext ✅

### Check Console
- [ ] No `console.log()` with passwords
- [ ] No sensitive data leaked

### Check Middleware
- [ ] Try accessing protected endpoint with `mot_de_passe_temporaire=true`:
```bash
curl -H "Authorization: Bearer <token>" http://localhost:8000/api/v1/dashboard
```
- [ ] **Expected:** 403 { code: "PASSWORD_CHANGE_REQUIRED" }

---

## 📝 Notes & Issues

| Issue | Priority | Status | Resolution |
|-------|----------|--------|------------|
| | 🔴 | | |
| | 🟡 | | |
| | 🟢 | | |

---

## ✅ Final Validation

### All Tests Passed?
- [ ] YES - Ready for production
- [ ] NO - See notes above, fix issues, retest

### Sign-Off
- **Tester Name:** ________________
- **Date:** ________________
- **Status:** ✅ PASSED / ❌ FAILED / 🟡 NEEDS FIXES

**Notes:**
```


```

---

**Total Tests:** 9  
**Tests Passed:** __/9  
**Tests Failed:** __/9  
**Success Rate:** ____%
