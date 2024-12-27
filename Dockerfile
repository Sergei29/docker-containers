FROM alpine:3.19

# Install required packages
RUN apk add --update nodejs npm

# Create a new user and group
RUN addgroup -S node && adduser -S node -G node

# Change the user to node
USER node

# Create app directory
WORKDIR /home/node/app

# Copy package.json and package-lock.json
COPY --chown=node:node package*.json ./

# Install app dependencies
RUN npm ci

# Copy app source code
COPY --chown=node:node . .

# Run the app
CMD ["npm", "start"]