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
alpine                     3.19.1       ace17d5d883e   11 months ago    7.73MB
```

- `docker rmi 7f998fb440a9` delete image by ID, will delete `my-node-app:3` image
- `docker rmi --force 7f998fb440a9` delete image if used by other processes
- `docker scout quickview alpine:3.19.1` scan the image for security summary of vulnerabilities
- `docker scout cves alpine:3.19.1` scan the image for security vulnerabilities in details

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

## Multi-stage build
- 🏗️ What if we want to build the app, for which we may need some packages, however, once the application is built, these packages may not be needed
- 😜 Multi-stage builds allow you to separate the build environment from the runtime environment. This means that only the necessary files and dependencies are included in the final image, significantly reducing its size.
- 👍 By isolating different build stages, you can reuse layers and cache intermediate builds. This can speed up subsequent builds since unchanged layers can be reused without recompilation.
- 💥 Smaller images with fewer dependencies reduce the attack surface for potential vulnerabilities. By excluding development tools and unnecessary packages from the final image, you minimize security risks.
- 🏠🏠🏠 Multi-stage builds allow you to manage complex builds within a single Dockerfile instead of maintaining multiple Dockerfiles for different environments (e.g., development, testing, production). This simplifies maintenance and improves readability.
- ✍️ You can perform all build steps in one Dockerfile while ensuring that only the essential components are present in the final image. This leads to a cleaner development workflow and easier debugging of specific build stages.
- 🏎️ 🏁 By keeping only what is necessary for running the application in the final image, you optimize resource usage on both local and cloud environments, leading to faster deployments and improved performance.

```Dockerfile
# Build step
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
```

- then we build this new image using the large builder image , but the output will be a small alpine result
```sh
docker build . -t node-express-app:alpine-3
...
docker image ls
```

```sh
REPOSITORY                 TAG          IMAGE ID       CREATED             SIZE
node-express-app           alpine-3     695b3e93db84   19 seconds ago      67.1MB
node-express-app           alpine-2     56108b38392e   About an hour ago   75.4MB
node-express-app           alpine       c3a300a89c62   About an hour ago   135MB
node-express-app           1            b985fd171631   2 hours ago         1.1GB
```

- here we can see the new build image `node-express-app:alpine-3` to have size of 67.1MB

## Distroless- an alternative to Linux Alpine.

You may not want to use Alpine, this [blogpost](https://martinheinz.dev/blog/92) sums it up with two points:
- Alpine made some design choices that have some extremely rare edge cases that can cause failures and be very hard to diagnose. This arises from their choice of replacing the typical glibc with musl. Read the blog post if you want to know more. 
- Suffice to say, unless you're running Kubernetes at a large scale this shouldn't concern you; lots of people run Alpine and never see issues.
- Now Alpine isn't the only option!

The four projects to look to here, Wolfi (an open source project), Red Hat's Universal Base Image Micro, Debian's slim variant, and Google's Distroless. We are going to focus on Distroless because it is currently the most popular but feel free to experiment!

"Distroless" is a bit of a lie as it still based on Debian, but to their point, they've stripped away essentially everything except what is 100% necessary to run your containers. This means you need to install everything you need to get running. It means no package manager. It means it is truly as bare bones as it can get.

```Dockerfile
# build stage
FROM node:20 AS node-builder
WORKDIR /build
COPY package-lock.json package.json ./
RUN npm ci
COPY . .

# runtime stage
FROM gcr.io/distroless/nodejs20
COPY --from=node-builder --chown=node:node /build /app
WORKDIR /app
CMD ["index.js"]
```

- `docker build . -t node-express-app:distroless`

```sh
REPOSITORY                 TAG          IMAGE ID       CREATED         SIZE
node-express-app           distroless   159eeedc8321   4 seconds ago   133MB
node-express-app           alpine-3     695b3e93db84   15 hours ago    67.1MB
node-express-app           alpine-2     56108b38392e   16 hours ago    75.4MB
node-express-app           alpine       c3a300a89c62   16 hours ago    135MB
```