# Build step, we take a full, large node image to build the app
FROM node:20 as node-builder
RUN mkdir -p /build
WORKDIR /build
COPY package*.json ./
RUN npm ci
COPY . .

# Production step
FROM gcr.io/distroless/nodejs20
COPY --from=node-builder --chown=node:node /build /app
WORKDIR /app
CMD [ "index.js" ]