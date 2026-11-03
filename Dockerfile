
# Global build argument
ARG NODE_VERSION=26

# =================================
# STAGE 1 - BUILDER
# =================================

FROM node:${NODE_VERSION}-bookworm-slim AS builder

ARG NODE_VERSION

WORKDIR /app

# Copy dependency files first
COPY package.json package-lock.json ./

# Exec form RUN
RUN ["npm", "ci"]

# Copy TypeScript configuration and source
COPY tsconfig.json ./
COPY src ./src

# Build TypeScript application
RUN npm run build


# =================================
# STAGE 2 - PRODUCTION
# =================================

FROM node:${NODE_VERSION}-bookworm-slim AS production

ARG APP_VERSION=1.0.0

# Environment variables
ENV NODE_ENV=production \
    PORT=3000 \
    APP_VERSION=${APP_VERSION} \
    DATA_DIR=/app/data

# Image metadata
LABEL org.opencontainers.image.title="docker-full-practical" \
      org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.description="Beginner Docker learning application"

WORKDIR /app

# Copy dependency files
COPY package.json package-lock.json ./

# Install production dependencies only
RUN npm ci --omit=dev && \
    npm cache clean --force

# Copy only built application from builder
COPY --from=builder --chown=node:node /app/dist ./dist

# Create data directory and set permissions
RUN mkdir -p /app/data && \
    chown -R node:node /app/data

# Persistent data location
VOLUME ["/app/data"]

# Run as non-root user
USER node

# Document application port
EXPOSE 3000

# Health monitoring
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD ["node", "-e", "require('http').get('http://127.0.0.1:3000/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"]

# Main executable
ENTRYPOINT ["node"]

# Default application file
CMD ["dist/app.js"]
