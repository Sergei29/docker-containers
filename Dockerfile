# Build step, we take a full, large node image to build the app
FROM node:20 as node-builder
RUN mkdir -p /build
WORKDIR /build
COPY package*.json ./
RUN npm ci
COPY . .

# Production step
FROM alpine:3.19
RUN apk add --update nodejs
RUN addgroup -S node && adduser -S node -G node
USER node
RUN mkdir -p /home/node/app
WORKDIR /home/node/app
COPY --from=node-builder --chown=node:node /build .
CMD [ "node", "index.js" ]