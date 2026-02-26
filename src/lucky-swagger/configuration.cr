require "habitat"

module LuckySwagger
  # Supported route filtering modes:
  # - :all - Include all routes (except HEAD)
  # - :api_only - Only include routes with "api" in the path (legacy behavior)
  # - Regex - Include routes matching the regex pattern
  alias IncludeRoutes = Symbol | Regex

  # Server configuration for OpenAPI servers array
  alias ServerConfig = NamedTuple(url: String, description: String)

  # Security scheme definition for OpenAPI components.securitySchemes
  alias SecurityScheme = Hash(String, String)

  # Security requirement for OpenAPI security array (e.g., [{"bearerAuth" => [] of String}])
  alias SecurityRequirement = Hash(String, Array(String))

  Habitat.create do
    # API metadata
    setting title : String = "API"
    setting description : String = "API documentation"
    setting version : String = "1.0.0"

    # Servers configuration
    setting servers : Array(ServerConfig) = [] of ServerConfig

    # Route filtering - which routes to include in the OpenAPI spec
    # :all (default) includes all routes, :api_only includes only routes with "api" in path
    # Regex allows custom filtering based on route path patterns
    setting include_routes : IncludeRoutes = :all

    # Security schemes for authentication/authorization
    # Example: {"bearerAuth" => {"type" => "http", "scheme" => "bearer", "bearerFormat" => "JWT"}}
    setting security_schemes : Hash(String, SecurityScheme) = {} of String => SecurityScheme

    # Default security requirements applied to all endpoints (unless overridden)
    # Example: [{"bearerAuth" => [] of String}]
    setting default_security : Array(SecurityRequirement) = [] of SecurityRequirement
  end
end
