#!/bin/bash
if ! command -v gawk; then
  echo "Command awk not found. Please install gawk to run this script."
  exit
fi
if ! command -v docker; then
  echo "Command docker not found. Please install docker to run this script."
  exit
fi
echo "Initializing the setup with docker..."
echo "Building"
docker compose build
echo "Install rails gems: bundle install in a volume for the rails service"
docker compose run --rm --no-deps rails /bin/bash -c "bundle install"
echo "Initializing postgresql database service"
docker compose up -d db
echo "Waiting"
sleep 5
echo "Run db:setup to initialize the database with tables"
docker compose run --rm --no-deps rails /bin/bash -c "rails db:setup"
echo "Run db:seed to seed the database with initial data"
docker compose run --rm --no-deps rails /bin/bash -c "rails db:seed"
