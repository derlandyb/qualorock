# Dev-server Dockerfile for the landing-page-plans (unauthenticated public
# React/Tailwind) submodule (AD-004). Mirrors website/Dockerfile's pattern (T2).
FROM node:22-alpine

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install

COPY . .

# Fixed dev-server port, distinct from web-app (5173) and admin-panel (5174).
EXPOSE 5175

CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "5175"]
