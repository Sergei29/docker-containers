FROM node:20

USER node

WORKDIR /home/node/app

# Copy package.json and package-lock.json
COPY --chown=node package*.json ./

# Install dependencies
RUN npm ci

# Copy the rest of the files
# This is done after the npm ci so the package installation steps can be cached
COPY --chown=node  . .

CMD [ "npm", "start" ]