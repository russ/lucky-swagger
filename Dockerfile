FROM docker.io/crystallang/crystal:latest

WORKDIR /app

# Copy everything and install shards
COPY . .
RUN shards install --ignore-crystal-version

CMD ["crystal", "spec", "--no-color"]
