# Dev-server Dockerfile for the admin-panel (React/Tailwind) submodule (AD-004).
# Mirrors website/Dockerfile's pattern (T2). Runs the Vite dev server directly.
FROM node:22-alpine

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install

COPY . .

# Fixed dev-server port, distinct from web-app (5173) and landing-page-plans (5175).
EXPOSE 5174

CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "5174"]
