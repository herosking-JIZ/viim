# Intégration Keycloak - Frontend React

## 1. Installation des dépendances

```bash
cd web/n-djigi

npm install keycloak-js axios
```

## 2. Créer le service Keycloak

Créer `src/services/keycloakService.js`:

```javascript
import Keycloak from 'keycloak-js';

const keycloakConfig = {
  url: process.env.REACT_APP_KEYCLOAK_URL,
  realm: process.env.REACT_APP_KEYCLOAK_REALM,
  clientId: process.env.REACT_APP_KEYCLOAK_CLIENT_ID
};

let keycloakInstance = null;

/**
 * Initialiser Keycloak
 */
export const initKeycloak = async () => {
  if (!keycloakInstance) {
    keycloakInstance = new Keycloak(keycloakConfig);
    
    try {
      const authenticated = await keycloakInstance.init({
        onLoad: 'login-required', // ou 'check-sso' pour optionnel
        silentCheckSsoRedirectUri: window.location.origin + '/silent-check-sso.html',
        pkceMethod: 'S256'
      });
      
      console.log('✅ Keycloak initialisé:', authenticated);
      
      if (authenticated) {
        // Setup token refresh
        setupTokenRefresh();
      }
      
      return authenticated;
    } catch (error) {
      console.error('❌ Erreur Keycloak:', error);
      throw error;
    }
  }
  
  return keycloakInstance.authenticated;
};

/**
 * Obtenir l'instance Keycloak
 */
export const getKeycloakInstance = () => {
  if (!keycloakInstance) {
    throw new Error('Keycloak n\'est pas initialisé');
  }
  return keycloakInstance;
};

/**
 * Obtenir le token d'accès
 */
export const getAccessToken = () => {
  if (!keycloakInstance) return null;
  return keycloakInstance.token;
};

/**
 * Obtenir les infos utilisateur
 */
export const getUserInfo = () => {
  if (!keycloakInstance) return null;
  return keycloakInstance.tokenParsed;
};

/**
 * Obtenir les rôles
 */
export const getUserRoles = () => {
  if (!keycloakInstance) return [];
  
  const realmRoles = keycloakInstance.tokenParsed?.realm_access?.roles || [];
  const clientRoles = keycloakInstance.tokenParsed?.resource_access?.[keycloakConfig.clientId]?.roles || [];
  
  return [...new Set([...realmRoles, ...clientRoles])];
};

/**
 * Vérifier si l'utilisateur a un rôle
 */
export const hasRole = (role) => {
  const roles = getUserRoles();
  return roles.includes(role);
};

/**
 * Setup du rafraîchissement automatique du token
 */
const setupTokenRefresh = () => {
  if (!keycloakInstance) return;
  
  // Rafraîchir le token 30 secondes avant son expiration
  setInterval(() => {
    keycloakInstance.updateToken(30)
      .then(refreshed => {
        if (refreshed) {
          console.log('🔄 Token rafraîchi');
        }
      })
      .catch(() => {
        console.warn('⚠️  Impossible de rafraîchir le token');
        logout();
      });
  }, 60000); // Vérifier toutes les minutes
};

/**
 * Logout
 */
export const logout = () => {
  if (keycloakInstance) {
    keycloakInstance.logout({ redirectUri: window.location.origin });
  }
};

/**
 * Login avec redirect
 */
export const login = () => {
  if (keycloakInstance) {
    keycloakInstance.login();
  }
};

export default keycloakInstance;
```

## 3. Créer un Context React

Créer `src/context/KeycloakContext.jsx`:

```javascript
import React, { createContext, useContext, useEffect, useState } from 'react';
import { 
  initKeycloak, 
  getKeycloakInstance, 
  getAccessToken, 
  getUserInfo, 
  getUserRoles,
  hasRole,
  logout
} from '../services/keycloakService';

const KeycloakContext = createContext();

export const KeycloakProvider = ({ children }) => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [user, setUser] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    const init = async () => {
      try {
        const authenticated = await initKeycloak();
        setIsAuthenticated(authenticated);
        
        if (authenticated) {
          setUser({
            info: getUserInfo(),
            roles: getUserRoles(),
            token: getAccessToken()
          });
        }
      } catch (err) {
        setError(err.message);
        console.error('Erreur initialisation Keycloak:', err);
      } finally {
        setIsLoading(false);
      }
    };

    init();
  }, []);

  const value = {
    isAuthenticated,
    isLoading,
    user,
    error,
    keycloak: getKeycloakInstance(),
    getToken: getAccessToken,
    hasRole: hasRole,
    logout: logout
  };

  return (
    <KeycloakContext.Provider value={value}>
      {children}
    </KeycloakContext.Provider>
  );
};

export const useKeycloak = () => {
  const context = useContext(KeycloakContext);
  
  if (!context) {
    throw new Error('useKeycloak doit être utilisé à l\'intérieur d\'un KeycloakProvider');
  }
  
  return context;
};
```

## 4. Modifier le point d'entrée de l'app

Modifier `src/index.js` ou `src/main.jsx`:

```javascript
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import { KeycloakProvider } from './context/KeycloakContext';
import LoadingScreen from './components/LoadingScreen';

const root = ReactDOM.createRoot(document.getElementById('root'));

root.render(
  <React.StrictMode>
    <KeycloakProvider>
      <App />
    </KeycloakProvider>
  </React.StrictMode>
);
```

## 5. Créer un composant ProtectedRoute

Créer `src/components/ProtectedRoute.jsx`:

```javascript
import React from 'react';
import { Navigate } from 'react-router-dom';
import { useKeycloak } from '../context/KeycloakContext';

export const ProtectedRoute = ({ children, requiredRoles = [] }) => {
  const { isAuthenticated, isLoading, hasRole } = useKeycloak();

  if (isLoading) {
    return <div className="flex items-center justify-center h-screen">Chargement...</div>;
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  if (requiredRoles.length > 0) {
    const hasRequiredRole = requiredRoles.some(role => hasRole(role));
    
    if (!hasRequiredRole) {
      return <Navigate to="/unauthorized" replace />;
    }
  }

  return children;
};
```

## 6. Créer le composant de Login

Créer `src/components/Login.jsx`:

```javascript
import React from 'react';
import { useKeycloak } from '../context/KeycloakContext';
import { login } from '../services/keycloakService';

export const Login = () => {
  const { isLoading } = useKeycloak();

  return (
    <div className="flex items-center justify-center min-h-screen bg-gradient-to-r from-blue-500 to-purple-600">
      <div className="bg-white rounded-lg shadow-xl p-8">
        <h1 className="text-3xl font-bold mb-6 text-gray-800">N'DJIGI</h1>
        <p className="text-gray-600 mb-8">Connectez-vous pour continuer</p>
        
        <button
          onClick={login}
          disabled={isLoading}
          className="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 px-4 rounded-lg transition duration-200"
        >
          {isLoading ? 'Chargement...' : 'Se connecter avec Keycloak'}
        </button>
      </div>
    </div>
  );
};

export default Login;
```

## 7. Créer un composant UserProfile

Créer `src/components/UserProfile.jsx`:

```javascript
import React from 'react';
import { useKeycloak } from '../context/KeycloakContext';

export const UserProfile = () => {
  const { user, logout } = useKeycloak();

  if (!user) return null;

  const { info, roles } = user;

  return (
    <div className="flex items-center gap-4">
      <div className="text-right">
        <p className="font-semibold">{info.name}</p>
        <p className="text-sm text-gray-500">{info.email}</p>
        <p className="text-xs text-gray-400">Rôles: {roles.join(', ')}</p>
      </div>
      
      <button
        onClick={logout}
        className="ml-4 px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
      >
        Déconnexion
      </button>
    </div>
  );
};

export default UserProfile;
```

## 8. Utiliser dans un composant

Exemple d'utilisation:

```javascript
import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { useKeycloak } from '../context/KeycloakContext';

export const Dashboard = () => {
  const { user, keycloak } = useKeycloak();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await axios.get(
          `${process.env.REACT_APP_API_URL}/utilisateurs`,
          {
            headers: {
              Authorization: `Bearer ${keycloak.token}`
            }
          }
        );
        setData(response.data);
      } catch (error) {
        console.error('Erreur:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [keycloak.token]);

  if (loading) return <div>Chargement...</div>;

  return (
    <div>
      <h1>Bienvenue, {user?.info?.name}</h1>
      {/* Afficher vos données */}
    </div>
  );
};
```

## 9. Configuration .env

Créer/modifier `web/n-djigi/.env`:

```env
REACT_APP_API_URL=http://localhost:8000/api/v1
REACT_APP_KEYCLOAK_URL=http://localhost:8080
REACT_APP_KEYCLOAK_REALM=ndjigi
REACT_APP_KEYCLOAK_CLIENT_ID=ndjigi-web
```

## 10. Configurer l'axe HTTP

Créer `src/services/apiService.js`:

```javascript
import axios from 'axios';
import { getKeycloakInstance } from './keycloakService';

const API_BASE_URL = process.env.REACT_APP_API_URL;

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Ajouter le token à chaque requête
apiClient.interceptors.request.use(
  (config) => {
    try {
      const keycloak = getKeycloakInstance();
      if (keycloak && keycloak.token) {
        config.headers.Authorization = `Bearer ${keycloak.token}`;
      }
    } catch (error) {
      console.warn('Impossible d\'ajouter le token:', error.message);
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Gérer les erreurs 401
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      try {
        const keycloak = getKeycloakInstance();
        if (keycloak) {
          keycloak.logout();
        }
      } catch (err) {
        console.error('Erreur logout:', err);
      }
    }
    return Promise.reject(error);
  }
);

export default apiClient;
```

## 11. Fichier silent-check-sso.html

Créer `public/silent-check-sso.html`:

```html
<!DOCTYPE html>
<html>
  <head>
    <title>silent-check-sso</title>
  </head>
  <body>
    <script>
      parent.postMessage(location.href, location.origin);
    </script>
  </body>
</html>
```

## Résumé

Après ces étapes, votre application React:

1. ✅ Initialise Keycloak au démarrage
2. ✅ Redirige vers le login si non authentifié
3. ✅ Rafraîchit le token automatiquement
4. ✅ Ajoute le token à chaque requête API
5. ✅ Gère les rôles et permissions
6. ✅ Affiche les infos utilisateur

## Dépannage

### Token non ajouté aux requêtes
- Vérifier que `REACT_APP_KEYCLOAK_URL` est correcte
- Vérifier que `REACT_APP_KEYCLOAK_CLIENT_ID` correspond au client web

### Redirection infinie
- Vérifier que les `Valid Redirect URIs` dans Keycloak incluent votre URL

### CORS error
- Ajouter votre URL au `Web Origins` du client web dans Keycloak
