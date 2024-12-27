## Basic Docker commands

```sh
docker ps
```

logging all docker processes

```sh
CONTAINER ID   IMAGE                       COMMAND       CREATED          STATUS          PORTS                    NAMES
6f2e737393ce   node-express-app:1   "npm start"   45 seconds ago   Up 44 seconds   0.0.0.0:3001->3000/tcp   brave_clarke
```

- `docker run -p 3001:3000 --rm node-express-app:1` run the application that is using port 3000, but publish it to the port 3001, meaning the app code is using port 3000, but the port exposed is port 3001, we need to call `http://localhost:3001` for example.

- `docker logs --follow 6f2e737393ce` will show the current container terminal logs
- `docker exec -it 6f2e737393ce sh` will execute interactively the container by running the shell terminal inside it
- `docker exec -it 6f2e737393ce cat /etc/issue` logs the Linux version used for this image.
- `docker image ls`, list all current local images available
  
```sh
REPOSITORY                 TAG          IMAGE ID       CREATED          SIZE
node-express-app           alpine-2     56108b38392e   26 minutes ago   75.4MB
node-express-app           alpine       c3a300a89c62   52 minutes ago   135MB
node-express-app           1            b985fd171631   56 minutes ago   1.1GB
my-node-app                3            7f998fb440a9   5 days ago       1.09GB
```

- `docker rmi 7f998fb440a9` delete image by ID, will delete `my-node-app:3` image
- `docker rmi --force 7f998fb440a9` delete image if used by other processes

## To create a basic docker image

```Dockerfile
FROM node:20
USER node
WORKDIR /home/node/app
RUN npm ci
CMD [ "npm", "start" ]
```

## To cache the installation layers

```Dockerfile
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
```

## To create a small container using node alpine

```Dockerfile
FROM node:20-alpine
USER node
WORKDIR /home/node/app
RUN npm ci
CMD [ "npm", "start" ]
```
## To create a small container from scratch, using Linux Alpine

```Dockerfile
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
```
