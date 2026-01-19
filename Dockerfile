# This Dockerfile builds both services using docker-compose
# For Coolify: Use "Docker Compose" resource type instead, pointing to docker-compose.yml

# If you must use single Dockerfile, this builds the backend:
FROM node:20-alpine AS base

# Install dependencies
FROM base AS deps
RUN apk add --no-cache libc6-compat python3 make g++
WORKDIR /app

COPY server/package.json server/package-lock.json* ./
RUN npm ci

# Build
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY server/ .

ENV NODE_ENV=production
RUN npm run build

# Production
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=12004

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 strapi

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/config ./config
COPY --from=builder /app/public ./public
COPY --from=builder /app/scripts ./scripts
COPY --from=builder /app/src ./src

RUN mkdir -p .tmp public/uploads
RUN chown -R strapi:nodejs .tmp public/uploads

USER strapi

EXPOSE 12004

CMD ["npm", "run", "start"]
