#!/bin/sh
set -e
PWD=$(pwd)
echo "\n\n******************\n"
echo "Répertoire initial: "
echo "\t$PWD"
echo "\n******************\n"

FILE=$PWD/README.md
if test -f "$FILE"; then
    echo "$FILE exists."
    echo "\n\n******************\n"
    echo "DESTROY ALL: "
    echo "\t$PWD"
    echo "\n******************\n"
    sudo rm -Rf DATAS Makefile README.md .env .env.example docker-compose.yml .gitignore engine scripts front
    exit 0
fi

mkdir -p engine/src DATAS scripts
touch Makefile README.md .env .env.example docker-compose.yml .gitignore engine/src/main.mjs engine/Dockerfile engine/.dockerignore engine/package.json scripts/build.sh scripts/clean.sh scripts/start.sh scripts/stop.sh scripts/build_start.sh
tee -a engine/package.json <<EOF
{
    "name": "engine",
    "version": "0.1.0",
    "description": "",
    "main": "src/main.mjs",
    "type": "module",
        "scripts": {
      "dev": "nodemon src/main.mjs",
      "start": "node src/main.mjs"
    },
    "keywords": [
      "node",
      "docker",
      "express"
    ],
    "author": "Olivier Heimerdinger <olivier@heimerdinger.me>",
    "license": "ISC",
    "dependencies": {
      "express": "^4.17.3",
      "fs-extra": "^10.0.1"
    },
    "devDependencies": {
      "nodemon": "^2.0.15"
    }
}
EOF

tee -a docker-compose.yml <<EOF
version: "3.7"

services:
  engine:
    container_name: $CONTAINER_NAME
    build: ./engine
    restart: always
    env_file: ./.env
    volumes:
      - ./engine/src:/app/src
      - ./DATAS:/var/lib/data
      - ./front/public:/home/public
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.${PROJECT_NAME}_web.loadbalancer.server.port=3000"
      - "traefik.http.routers.${PROJECT_NAME}_web.entrypoints=http"
      - "traefik.http.routers.${PROJECT_NAME}_web.rule=Host(`${HOST}`)"
EOF

tee -a .env.example <<EOF
CONTAINER_NAME=XXX_engine
PROJECT_NAME=XXX_project
HOST=XXX.localhost
EOF

tee -a engine/src/main.mjs<<EOF
import express from 'express'

const app = express()

app.use(express.static('/home/public'))

app.listen(3000, () => {
    console.log('Engine READY', new Date().toISOString())
})
EOF

tee -a engine/.dockerignore <<EOF
node_modules
*lock*
EOF

tee -a .gitignore <<EOF
node_modules
.env
EOF

tee -a engine/Dockerfile <<EOF
FROM node:16.13.2-alpine3.15

WORKDIR /app
COPY . .

RUN yarn

CMD ["yarn", "dev"]
EOF


tee -a Makefile<<EOF
.DEFAULT_GOAL := help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*75508'  | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", 755081, 755082}'

build: ## build project
	./scripts/build.sh

clean: ## Remove all you need
	./scripts/clean.sh

start: ## Starting project
	./scripts/start.sh

stop: ## Stoppping projetct
	./scripts/stop.sh

build-start: ## Rebuild and start project
	./scripts/build_start.sh

EOF

tee -a scripts/build.sh <<EOF
#!/bin/bash

set -e

docker-compose build
EOF

tee -a scripts/build_start.sh <<EOF
#!/bin/bash

set -e

docker-compose down && docker-compose up --build -d  && docker-compose logs -f
EOF

tee -a scripts/clean.sh <<EOF
#!/bin/bash

set -e

docker-compose down && sudo rm -Rf DATAS
EOF

tee -a scripts/start.sh <<EOF
#!/bin/bash

set -e

docker-compose up -d && docker-compose logs -f
EOF

tee -a scripts/stop.sh <<EOF
#!/bin/bash

set -e

docker-compose stop
EOF

chmod +x scripts/build.sh scripts/clean.sh scripts/start.sh scripts/stop.sh scripts/build_start.sh

cd $PWD
npx degit sveltejs/template front

git init && cd front && yarn && yarn build

cd $PWD
