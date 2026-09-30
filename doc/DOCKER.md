# Using Docker to Develop TSP

Use the `Dockerfile` and Compose examples in `docker/` to set up a development environment.

1. Copy a Compose example and its database configuration. For PostgreSQL:

   ```sh
   cp docker/docker-compose.development.postgresql.yml docker-compose.yml
   cp docker/database.postgresql.yml config/database.yml
   cp config/site.example.yml config/site.yml
   ```

2. Set the application secrets and other settings in `config/site.yml`. Set the
   container user ID to match your host user so bind-mounted files stay writable:

   ```sh
   export CONTAINER_USERID=$(id -u)
   docker compose build
   ```

3. Start the database and wait until it is ready. Skip this command for SQLite:

   ```sh
   docker compose up --detach db
   ```

4. Create and seed a new development database:

   ```sh
   docker compose run --rm web bundle exec rake db:setup
   ```

5. Run the complete test suite:

   ```sh
   docker compose run --rm -e RAILS_ENV=test web bundle exec rake db:migrate
   docker compose run --rm -e RAILS_ENV=test web bundle exec rspec
   ```

6. Start the application:

   ```sh
   docker compose up
   ```

Rebuild the image after changes to `Gemfile`, `Gemfile.lock`, or `Dockerfile`.
When upgrading a database image, follow the database vendor’s upgrade procedure
instead of reusing an incompatible data volume.
