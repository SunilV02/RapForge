# Use official Node.js LTS slim image
FROM node:22-slim

# Set working directory
WORKDIR /app

# Copy package files first (layer caching — only re-runs npm ci if deps change)
COPY package*.json ./

# Install production dependencies only
RUN npm ci --omit=dev

# Install CAP CLI for cds-serve
RUN npm install -g @sap/cds-dk

# Copy application source
COPY . .

# Expose CAP default port
EXPOSE 4004

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD node -e "require('http').get('http://localhost:4004/', r => r.statusCode === 200 ? process.exit(0) : process.exit(1))"

# Start the CAP server
CMD ["cds-serve"]
