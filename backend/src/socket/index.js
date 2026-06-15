/**
 * SOCKET/INDEX.JS
 * Point d'entrée Socket.io pour la Phase 2 (authentification + rooms)
 *
 * - Instancie le serveur Socket.io
 * - Crée le namespace /chat
 * - Applique le middleware d'authentification au namespace
 * - Gère les événements de connexion/déconnexion
 * - Enregistre les handlers de conversation (auto-join + join)
 * - Retourne l'instance io pour attachement au serveur HTTP
 */

const { Server } = require('socket.io');
const { authMiddleware } = require('./middleware/authMiddleware');
const { registerConversationHandlers } = require('./handlers/conversationHandler');

/**
 * Initialise le serveur Socket.io sur un serveur HTTP existant
 * @param {http.Server} httpServer - Serveur HTTP Express
 * @returns {Server} Instance Socket.io
 */
function initSocket(httpServer) {
  // Origines CORS autorisées (web + mobile dev)
  const corsOrigins = [
    'http://localhost:3000',      // Web local
    'http://localhost:8081',      // Alternative dev
    'http://web:3000',            // Docker network
    'http://10.3.3.49:3000',      // Dev external IP (web)
    'http://10.3.3.49:8000',      // Dev external IP (backend Socket.io)
    'http://10.0.2.2:8000',       // Android emulator
    'http://192.168.11.104:8000', // Réseau local
  ];

  // Instancier Socket.io
  const io = new Server(httpServer, {
    cors: {
      origin: corsOrigins,
      credentials: true,
      methods: ['GET', 'POST']
    }
  });

  // === Namespace /chat (Phase 2) ===
  const chatNamespace = io.of('/chat');

  // Appliquer le middleware d'authentification au namespace /chat
  chatNamespace.use(authMiddleware);

  // Événement de connexion sur le namespace /chat
  chatNamespace.on('connection', (socket) => {
    const userId = socket.data.user?.id_utilisateur || 'unknown';
    console.log(`✅ Socket.io /chat connexion: ${socket.id} | User: ${userId}`);

    // Enregistrer les handlers de conversation (auto-join + join)
    registerConversationHandlers(socket);

    // Événement de déconnexion
    socket.on('disconnect', () => {
      console.log(`❌ Socket.io /chat déconnexion: ${socket.id} | User: ${userId}`);
    });
  });

  return io;
}

module.exports = { initSocket };
