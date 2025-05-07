# first stage
FROM node:22 AS builder
WORKDIR /app

# Install pnpm
RUN npm install -g pnpm

# Kopiere package.json und pnpm-lock.yaml
COPY package.json pnpm-lock.yaml ./

# Lösche alte node_modules und installiere ALLE Abhängigkeiten
RUN rm -rf node_modules && pnpm install --frozen-lockfile --verbose

# Kopiere den gesamten restlichen Quellcode
COPY . .

# Generiere SvelteKit spezifische Typen und Konfigurationen
RUN rm -rf .svelte-kit && npx svelte-kit sync

# Führe den Build-Prozess aus
RUN pnpm run build

# Entferne NUR die devDependencies NACH einem erfolgreichen Build
RUN pnpm prune --prod

# second stage (Produktions-Image)
FROM node:22-alpine
WORKDIR /app

# Kopiere nur die notwendigen Artefakte aus dem Builder-Stage
COPY --from=builder /app/build/ ./build/
COPY --from=builder /app/node_modules/ ./node_modules/
COPY --from=builder /app/server.js ./server.js
COPY --from=builder /app/package.json ./package.json

ENV PORT=5050 \
  NODE_ENV=production \
  ADDON=false

EXPOSE 5050
CMD ["node", "server.js"]
