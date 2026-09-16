# Dev-server Dockerfile for the web-app (React/Tailwind) submodule (AD-004).
# Runs the Vite dev server directly - not a production build.
FROM node:22-alpine

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install

COPY . .

# Fixed dev-server port, distinct from admin (5174) and landing-page-plans (5175).
EXPOSE 5173

CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "5173"]
