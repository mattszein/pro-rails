echo "Initializing the setup with docker..."
echo "Install rails gems: bundle install in a volume for the rails service"
docker compose run --rm --no-deps rails /bin/bash -c "bundle install"
echo "Initializing postgresql database service"
docker compose up -d db
sleep 2
echo "Run db:setup to initialize the database with tables"
docker compose run --rm --no-deps rails /bin/bash -c "rails db:setup"
echo "Run db:seed to seed the database with initial data"
docker compose run --rm --no-deps rails /bin/bash -c "rails db:seed"
