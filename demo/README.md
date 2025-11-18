# Lucky Swagger Demo Application

This demo application showcases all the features of the `lucky-swagger` library.

## Features Demonstrated

### 1. **Multiple API Resources**
- Users (CRUD operations)
- Posts (with filtering)
- Comments (nested under posts)
- Health check endpoint

### 2. **Parameter Types**
- **Path Parameters**: `/api/users/:user_id`, `/api/posts/:post_id/comments/:comment_id`
- **Query Parameters**: pagination, filtering, sorting
- **Optional Parameters**: `search`, `active`, `author_id`
- **Default Values**: `page=1`, `per_page=25`, `status="published"`
- **Multiple Types**: String, Int32, Bool

### 3. **HTTP Methods**
- GET (list and show endpoints)
- POST (create)
- PUT (update)
- DELETE (delete)

### 4. **Route Organization**
- Namespaced actions (`Api::Users::Index`, `Api::Posts::Comments::Show`)
- Nested resources (posts → comments)
- Tags automatically generated from namespaces

## Quick Start

### 1. Install Dependencies

```bash
cd demo
shards install
```

### 2. Generate OpenAPI Documentation

The OpenAPI YAML file is already generated at `swagger/api.yaml`. To regenerate it:

```bash
crystal tasks.cr -- lucky_swagger.generate_open_api -f ./swagger/api.yaml
```

### 3. Run the Server

```bash
crystal src/demo.cr
```

The server will start on `http://localhost:5000`

### 4. View SwaggerUI

Open your browser and navigate to:

```
http://localhost:5000/api-docs
```

You'll see the interactive SwaggerUI interface with all your API endpoints documented.

## API Endpoints

### Health
- `GET /api/health` - Check API health status

### Users
- `GET /api/users` - List all users (with pagination and filtering)
  - Query params: `page`, `per_page`, `search`, `active`, `sort_by`
- `POST /api/users` - Create a new user
- `GET /api/users/:user_id` - Show user details
- `PUT /api/users/:user_id` - Update user
- `DELETE /api/users/:user_id` - Delete user

### Posts
- `GET /api/posts` - List all posts
  - Query params: `author_id`, `status`, `limit`
- `GET /api/posts/:post_id` - Show post details

### Comments
- `GET /api/posts/:post_id/comments` - List comments for a post
  - Query params: `include_deleted`
- `GET /api/posts/:post_id/comments/:comment_id` - Show comment details

## Testing the API

### Using curl

```bash
# Health check
curl http://localhost:5000/api/health

# List users with pagination
curl "http://localhost:5000/api/users?page=1&per_page=10"

# List users with search
curl "http://localhost:5000/api/users?search=john"

# Show specific user
curl http://localhost:5000/api/users/123

# List posts by author
curl "http://localhost:5000/api/posts?author_id=456&status=published"

# List comments for a post
curl http://localhost:5000/api/posts/789/comments

# Show specific comment
curl http://localhost:5000/api/posts/789/comments/101
```

### Using SwaggerUI

1. Navigate to `http://localhost:5000/api-docs`
2. Click on any endpoint to expand it
3. Click "Try it out"
4. Fill in parameters
5. Click "Execute"
6. View the response

## Project Structure

```
demo/
├── src/
│   ├── actions/
│   │   ├── api/
│   │   │   ├── health.cr
│   │   │   ├── users/
│   │   │   │   ├── index.cr
│   │   │   │   ├── show.cr
│   │   │   │   ├── create.cr
│   │   │   │   ├── update.cr
│   │   │   │   └── delete.cr
│   │   │   └── posts/
│   │   │       ├── index.cr
│   │   │       ├── show.cr
│   │   │       └── comments/
│   │   │           ├── index.cr
│   │   │           └── show.cr
│   │   └── api_action.cr
│   ├── errors/
│   │   └── show.cr
│   ├── app_server.cr
│   └── demo.cr
├── swagger/
│   └── api.yaml
├── tasks/
│   └── generate_swagger.cr
├── tasks.cr
└── shard.yml
```

## How It Works

### 1. Action Definition

Each API action inherits from `ApiAction`:

```crystal
class Api::Users::Index < ApiAction
  param page : Int32 = 1
  param per_page : Int32 = 25

  get "/api/users" do
    json({message: "List users"})
  end
end
```

### 2. WebHandler Integration

The `AppServer` includes the `LuckySwagger::Handlers::WebHandler`:

```crystal
class AppServer < Lucky::BaseAppServer
  def middleware : Array(HTTP::Handler)
    [
      LuckySwagger::Handlers::WebHandler.new(
        swagger_url: "/api-docs",
        folder: "./swagger"
      ),
      # ... other handlers
    ] of HTTP::Handler
  end
end
```

### 3. OpenAPI Generation

The generator introspects Lucky's router and creates OpenAPI specs:
- Discovers all routes with "api" in the path
- Extracts path parameters (`:user_id` → `{user_id}`)
- Extracts query parameters from `param` declarations
- Organizes routes by tags based on namespace
- Generates complete OpenAPI 3.0.0 YAML

### 4. SwaggerUI Serving

The WebHandler:
- Serves SwaggerUI HTML at `/api-docs`
- Serves YAML files from the `swagger` folder
- Passes through other requests to the next handler

## Customization

### Change SwaggerUI URL

```crystal
LuckySwagger::Handlers::WebHandler.new(
  swagger_url: "/docs",  # Change from /api-docs to /docs
  folder: "./swagger"
)
```

### Multiple API Versions

Create multiple YAML files in the swagger folder:

```
swagger/
├── v1.yaml
└── v2.yaml
```

The WebHandler will automatically discover and list all YAML files in SwaggerUI.

### Custom OpenAPI Information

Edit the generated `swagger/api.yaml` file to customize:
- API title and description
- Server URLs
- Security schemes
- Response examples
- Schema definitions

## Learn More

- [lucky-swagger GitHub](https://github.com/marmaxev/lucky-swagger)
- [OpenAPI Specification](https://swagger.io/specification/)
- [Lucky Framework](https://luckyframework.org/)
