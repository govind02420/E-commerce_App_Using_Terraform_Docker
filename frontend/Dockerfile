# Build stage
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi
COPY . .
RUN npm run build

# Production stage
FROM nginx:stable-alpine
COPY --from=build /app/build /usr/share/nginx/html
# Remove default nginx conf if you have special routing; otherwise default works
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]



