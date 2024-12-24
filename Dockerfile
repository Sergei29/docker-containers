FROM node:20

USER node

WORKDIR /home/node/app

COPY --chown=node  . .

RUN npm ci

CMD [ "npm", "start" ]