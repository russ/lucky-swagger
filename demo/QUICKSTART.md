# Quick Start Guide

## Prerequisites

- Crystal 1.0.0 or higher
- Shards package manager

## Installation & Setup

### Option 1: Using the setup script (Recommended)

```bash
# Navigate to demo directory
cd demo

# Run the setup script
./setup.sh
```

### Option 2: Manual setup

```bash
# Navigate to demo directory
cd demo

# Install dependencies
shards install
```

**Note:** The OpenAPI spec is already generated at `swagger/api.yaml`. To regenerate it, you would run:
```bash
crystal tasks.cr -- lucky_swagger.generate_open_api -f ./swagger/api.yaml
```

## Running the Demo

**Important:** Make sure you've run the setup first (either with `./setup.sh` or `shards install`)!

```bash
# Start the server (from the demo directory)
crystal src/demo.cr

# Or build and run for better performance
crystal build src/demo.cr -o demo
./demo
```

**Note:** The `crystal` command must be run from the `demo` directory where the `shard.yml` file is located.

The server will start on http://localhost:5000

## Accessing SwaggerUI

Open your browser and go to:

```
http://localhost:5000/api-docs
```

You'll see the full API documentation with interactive "Try it out" functionality.

## Testing Endpoints

### Via curl

```bash
# Health check
curl http://localhost:5000/api/health

# List users
curl http://localhost:5000/api/users

# List users with pagination
curl "http://localhost:5000/api/users?page=2&per_page=10"

# Show specific user
curl http://localhost:5000/api/users/123

# List posts
curl http://localhost:5000/api/posts

# List comments for a post
curl http://localhost:5000/api/posts/1/comments
```

### Via SwaggerUI

1. Go to http://localhost:5000/api-docs
2. Expand any endpoint (e.g., "GET /api/users")
3. Click "Try it out"
4. Modify parameters if desired
5. Click "Execute"
6. View the response

## What You'll See

The demo showcases:

- ✅ **10 API endpoints** across 3 resources (Users, Posts, Comments)
- ✅ **Path parameters** (`:user_id`, `:post_id`, `:comment_id`)
- ✅ **Query parameters** with various types (Int32, String, Bool)
- ✅ **Default values** for parameters
- ✅ **Optional parameters** (nullable types)
- ✅ **Multiple HTTP methods** (GET, POST, PUT, DELETE)
- ✅ **Nested resources** (posts → comments)
- ✅ **Automatic tag organization** from namespaces

## Troubleshooting

### "Can't find file 'lucky_swagger'"

Make sure you ran `shards install` from the demo directory.

### Port 5000 already in use

Edit `src/demo.cr` and change the port:

```crystal
Lucky::Server.configure do |settings|
  settings.port = 3000  # Change to your preferred port
end
```

### Dependencies fail to install

Make sure you're running Crystal 1.0.0 or higher:

```bash
crystal --version
```
