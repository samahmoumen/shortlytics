FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# Vite bakes these in at build time. An empty backend URL makes axios use
# relative paths (/api/...), which the Ingress routes to the backend.
ARG VITE_BACKEND_URL=""
ARG VITE_REACT_FRONT_END_URL="http://dev.shortlytics.internal"
ARG VITE_REACT_SUBDOMAIN="http://dev.shortlytics.internal"
ENV VITE_BACKEND_URL=$VITE_BACKEND_URL \
    VITE_REACT_FRONT_END_URL=$VITE_REACT_FRONT_END_URL \
    VITE_REACT_SUBDOMAIN=$VITE_REACT_SUBDOMAIN

RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]