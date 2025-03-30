FROM mcr.microsoft.com/playwright:v1.51.1-jammy

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Build TypeScript
RUN npm run build

# Install Playwright browsers
RUN npx playwright install chromium

# Start the application
CMD ["npm", "start"]
