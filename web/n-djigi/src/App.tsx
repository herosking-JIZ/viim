import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from '@/contexts/AuthContext'
import { ToastProvider } from '@/hooks/useToast'
import { Toaster } from '@/components/Toaster'
import { AppLayout } from '@/layouts/AppLayout'

// Pages auth (publiques)
import Login from '@/pages/Login'
import ForgotPassword from '@/pages/auth/ForgotPassword'
import ResetPassword from '@/pages/auth/ResetPassword'
import NotFound from '@/pages/NotFound'

// Pages admin
import Dashboard from '@/pages/admin/Dashboard'
import Users from '@/pages/admin/Users'
import Documents from '@/pages/admin/Documents'
import Trips from '@/pages/admin/Trips'
import Finance from '@/pages/admin/Finance'
import Parkings from '@/pages/admin/Parkings'
import Support from '@/pages/admin/Support'
import Config from '@/pages/admin/Config'

// Pages gestionnaire
import ParkeurDashboard from '@/pages/parkeur/ParkeurDashboard'

// Page partagée
import ChangePassword from '@/pages/auth/ChangePassword'

// ─── ProtectedRoute ───────────────────────────────────────────
function ProtectedRoute({
  children,
  adminOnly = false,
}: {
  children: React.ReactNode
  adminOnly?: boolean
}) {
  const { user, loading } = useAuth()

  if (loading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    )
  }

  if (!user) return <Navigate to="/login" replace />

  // adminOnly : seuls admin et super_admin ont accès
  if (adminOnly && user.role !== 'admin' && user.role !== 'super_admin') {
    return <Navigate to="/" replace />
  }

  return <>{children}</>
}

// ─── Routes ───────────────────────────────────────────────────
function AppRoutes() {
  const { user } = useAuth()

  const isAdmin = user?.role === 'admin' || user?.role === 'super_admin'

  return (
    <Routes>
      {/* ── Routes publiques (sans layout) ─────────────────── */}
      <Route path="/login" element={<Login />} />
      <Route path="/auth/forgot-password" element={<ForgotPassword />} />
      {/* Le backend envoie un lien du type /auth/reset-password?token=XXXX */}
      <Route path="/auth/reset-password" element={<ResetPassword />} />

      {/* ── Routes protégées (avec layout) ─────────────────── */}
      <Route
        path="/"
        element={
          <ProtectedRoute>
            <AppLayout />
          </ProtectedRoute>
        }
      >
        {/* Index : dashboard selon le rôle */}
        <Route
          index
          element={isAdmin ? <Dashboard /> : <ParkeurDashboard />}
        />

        {/* Profil — accessible à tous les rôles connectés */}
        <Route path="profil/mot-de-passe" element={<ChangePassword />} />

        {/* Routes admin uniquement */}
        <Route
          path="utilisateurs"
          element={<ProtectedRoute adminOnly><Users /></ProtectedRoute>}
        />
        <Route
          path="documents"
          element={<ProtectedRoute adminOnly><Documents /></ProtectedRoute>}
        />
        <Route
          path="trajets"
          element={<ProtectedRoute adminOnly><Trips /></ProtectedRoute>}
        />
        <Route
          path="finances"
          element={<ProtectedRoute adminOnly><Finance /></ProtectedRoute>}
        />
        <Route
          path="parkings"
          element={<ProtectedRoute adminOnly><Parkings /></ProtectedRoute>}
        />
        <Route
          path="support"
          element={<ProtectedRoute adminOnly><Support /></ProtectedRoute>}
        />
        <Route
          path="configuration"
          element={<ProtectedRoute adminOnly><Config /></ProtectedRoute>}
        />
      </Route>

      <Route path="*" element={<NotFound />} />
    </Routes>
  )
}

// ─── Root ─────────────────────────────────────────────────────
export default function App() {
  return (
    <BrowserRouter>
      <ToastProvider>
        <AuthProvider>
          <AppRoutes />
          <Toaster />
        </AuthProvider>
      </ToastProvider>
    </BrowserRouter>
  )
}
