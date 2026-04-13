import React, { createContext, useContext, useState, useEffect, useCallback } from 'react'
import type { AuthUser, LoginResponseData, UserRole } from '@/types'
import { authService } from '@/services/api'

// ─── Clés localStorage ────────────────────────────────────────
const STORAGE_KEY_USER   = 'ndjigi_user'
const STORAGE_KEY_ACCESS = 'ndjigi_access_token'
const STORAGE_KEY_REFRESH = 'ndjigi_refresh_token'
const STORAGE_KEY_PERMISSIONS = 'ndjigi_permissions'

interface AuthContextValue {
  user: AuthUser | null
  permissions: string[]
  loading: boolean
  login: (email: string, password: string) => Promise<void>
  logout: () => Promise<void>
  // Vérifie si l'utilisateur a une permission donnée
  can: (permission: string) => boolean
}

const AuthContext = createContext<AuthContextValue | null>(null)

// ─── Helper : déduire le rôle principal depuis utilisateur_role ─
function getPrimaryRole(roles: { role: string; actif: boolean }[]): UserRole {
  const actifs = roles.filter((r) => r.actif).map((r) => r.role as UserRole)
  if (actifs.includes('admin') || actifs.includes('super_admin')) return 'admin'
  if (actifs.includes('gestionnaire')) return 'gestionnaire'
  if (actifs.includes('chauffeur')) return 'chauffeur'
  if (actifs.includes('proprietaire')) return 'proprietaire'
  return actifs[0] ?? 'passager'
}

// ─── Helper : construire AuthUser depuis LoginResponseData ──
export function buildAuthUser(data: LoginResponseData): AuthUser {
  const roles = data.user.utilisateur_role
    .filter((r) => r.actif)
    .map((r) => r.role as UserRole)

  return {
    id_utilisateur: data.user.id_utilisateur,
    email: data.user.email,
    nom: data.user.nom,
    prenom: data.user.prenom,
    numero_telephone: data.user.numero_telephone,
    photo_profil: data.user.photo_profil,
    role: getPrimaryRole(data.user.utilisateur_role),
    roles,
    permissions: data.permissions,
  }
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null)
  const [permissions, setPermissions] = useState<string[]>([])
  const [loading, setLoading] = useState(true)

  // ─── Restaurer la session au démarrage ─────────────────────
  useEffect(() => {
    const storedUser  = localStorage.getItem(STORAGE_KEY_USER)
    const storedPerms = localStorage.getItem(STORAGE_KEY_PERMISSIONS)
    const storedToken = localStorage.getItem(STORAGE_KEY_ACCESS)

    if (storedUser && storedToken) {
      try {
        const u: AuthUser = JSON.parse(storedUser)
        const p: string[] = storedPerms ? JSON.parse(storedPerms) : []
        setUser(u)
        setPermissions(p)
      } catch {
        // Données corrompues → on efface tout
        clearStorage()
      }
    }
    setLoading(false)
  }, [])

  // ─── Login ─────────────────────────────────────────────────
  const login = useCallback(async (email: string, password: string) => {
    // authService.login renvoie ApiResponse<LoginResponseData>
    const response = await authService.login({ email, mot_de_passe: password })

    // Construire l'objet AuthUser depuis la réponse backend
    const authUser = buildAuthUser(response)
    const perms = response.permissions

    // Stocker
    localStorage.setItem(STORAGE_KEY_ACCESS, response.tokens.accessToken)
    localStorage.setItem(STORAGE_KEY_REFRESH, response.tokens.refreshToken)
    localStorage.setItem(STORAGE_KEY_USER, JSON.stringify(authUser))
    localStorage.setItem(STORAGE_KEY_PERMISSIONS, JSON.stringify(perms))

    setUser(authUser)
    setPermissions(perms)
  }, [])

  // ─── Logout ────────────────────────────────────────────────
  const logout = useCallback(async () => {
    try {
      await authService.logout()
    } catch {
      // Ignorer les erreurs réseau au logout
    } finally {
      clearStorage()
      setUser(null)
      setPermissions([])
    }
  }, [])

  // ─── can() : vérifie une permission ────────────────────────
  const can = useCallback((permission: string) => {
    return permissions.includes(permission)
  }, [permissions])

  return (
    <AuthContext.Provider value={{ user, permissions, loading, login, logout, can }}>
      {children}
    </AuthContext.Provider>
  )
}

function clearStorage() {
  localStorage.removeItem(STORAGE_KEY_USER)
  localStorage.removeItem(STORAGE_KEY_ACCESS)
  localStorage.removeItem(STORAGE_KEY_REFRESH)
  localStorage.removeItem(STORAGE_KEY_PERMISSIONS)
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}

// Export des clés pour que api.ts puisse les lire
export { STORAGE_KEY_ACCESS, STORAGE_KEY_REFRESH }
