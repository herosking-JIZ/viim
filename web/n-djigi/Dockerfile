# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app

# Installer les dépendances
COPY package*.json ./
RUN npm ci

# Copier le code source
COPY . .

# Builder l'application Vite
RUN npm run build

# Stage 2: Runtime avec serveur Node simple
FROM node:20-alpine
WORKDIR /app

# Installer un serveur HTTP simple
RUN npm install -g serve

# Copier les fichiers compilés depuis le builder
COPY --from=builder /app/dist ./dist

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ || exit 1

# Servir l'application
CMD ["serve", "-s", "dist", "-l", "3000"]
