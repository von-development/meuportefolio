# Multi-stage Next.js Dockerfile optimized for production
# Based on Vercel's official recommendations and best practices

FROM node:18-alpine AS base
# Install dependencies only when needed
RUN apk add --no-cache g++ make py3-pip libc6-compat
WORKDIR /app

# Install dependencies based on the preferred package manager
COPY package.json package-lock.json* ./
EXPOSE 3000

FROM base AS builder
WORKDIR /app
COPY . .

# Disable Next.js telemetry during build
ENV NEXT_TELEMETRY_DISABLED 1

# Build the application
RUN npm ci --only=production && npm run build

# Production image, copy all the files and run next
FROM base AS production
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED 1

# Create a non-root user for security
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

# Copy built application from builder stage
COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/package.json ./package.json
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules

# Switch to non-root user
USER nextjs

# Start the application
CMD ["npm", "start"]

# Development stage for local development
FROM base AS dev
ENV NODE_ENV=development
WORKDIR /app

# Install all dependencies (including dev dependencies)
RUN npm install

# Copy source code
COPY . .

# Start development server
CMD ["npm", "run", "dev"] 