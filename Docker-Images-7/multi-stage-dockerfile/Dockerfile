# Stage 1: Build & Dependencies
FROM node:18-alpine AS builder
WORKDIR /app
COPY package.json .
COPY server.js .

# Stage 2: Production Lean Runtime
FROM node:18-alpine AS runner
WORKDIR /app
COPY --from=builder /app/package.json .
COPY --from=builder /app/server.js .

EXPOSE 3000
CMD ["node", "server.js"]
