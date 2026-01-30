FROM node:22-alpine

# Install system dependencies
RUN apk add --no-cache \
    git \
    python3 \
    make \
    g++ \
    curl \
    && rm -rf /var/cache/apk/*

# Create app directory
WORKDIR /app

# Install ClawdBot globally
RUN npm install -g clawdbot@latest

# Create data directory
RUN mkdir -p /root/.clawdbot

# Expose ClawdBot port
EXPOSE 18789

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD wget -q --spider http://localhost:18789 || exit 1

# Set environment
ENV NODE_ENV=production
ENV CLAWDBOT_PORT=18789

# Start ClawdBot gateway
CMD ["clawdbot", "gateway", "--port", "18789"]
