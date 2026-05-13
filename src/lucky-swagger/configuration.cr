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
    setting terms_of_service : String? = nil
    setting contact : NamedTuple(name: String?, email: String?, url: String?)? = nil
    setting license : NamedTuple(name: String, url: String?)? = nil

    # Servers configuration
    setting servers : Array(ServerConfig) = [] of ServerConfig

    # Route filtering - which routes to include in the OpenAPI spec.
    # :all (default) includes all routes except HEAD.
    # :api_only includes only routes whose path contains the literal string "api"
    #   — this does NOT match /v1/ prefix apps; use Regex for those instead.
    #   Example for /v1/ apps: include_routes: /^\/v1\//
    # Regex allows custom filtering based on route path patterns.
    setting include_routes : IncludeRoutes = :all

    # Security schemes for authentication/authorization
    # Example: {"bearerAuth" => {"type" => "http", "scheme" => "bearer", "bearerFormat" => "JWT"}}
    setting security_schemes : Hash(String, SecurityScheme) = {} of String => SecurityScheme

    # OAuth2 security schemes with full flow definitions (authorizationCode, clientCredentials, etc.)
    # Use LuckySwagger::OAuth2Scheme and LuckySwagger::OAuth2Flow to build the structure.
    setting oauth2_schemes : Hash(String, OAuth2Scheme) = {} of String => OAuth2Scheme

    # Default security requirements applied to all endpoints (unless overridden)
    # Example: [{"bearerAuth" => [] of String}]
    setting default_security : Array(SecurityRequirement) = [] of SecurityRequirement

    # Map of auth mixin/module names to security scheme names. Actions that
    # include a registered mixin get an inferred security requirement, with
    # all matched schemes AND-combined into a single requirement.
    # Example: {"Api::Auth::RequireAuthToken" => "bearerAuth"}
    setting auth_mixin_map : Hash(String, String) = {} of String => String

    # Namespace parts to strip when auto-generating tags from action class names.
    # Example: ["Api", "Actions", "V1", "V2"] turns Api::V1::Frontend::Users::Index
    # into ["Frontend > Users"].
    setting tag_strip_prefixes : Array(String) = ["Api", "Actions", "V1", "V2"]

    # Separator used when joining multiple remaining namespace parts into a tag.
    setting tag_separator : String = " > "

    # Tag used when every namespace part was stripped (i.e., nothing left to tag).
    setting default_tag : String = "default"

    # Runtime format map for parameter type inference. Keys are Crystal type name
    # strings (e.g., "UUID", "EmailAddress"); values are {type:, format:} pairs.
    # Example: {"UUID" => {type: "string", format: "uuid"}}
    # Note: schema property formats use @[LuckySwagger::ScalarFormat] annotation instead.
    setting format_map : Hash(String, NamedTuple(type: String, format: String)) = {} of String => NamedTuple(type: String, format: String)

    # Singularization overrides used at runtime (e.g. by custom tooling or extensions).
    # Note: compile-time convention discovery (Save<X>, <X>Serializer) uses built-in
    # heuristics (-ies→y, -ses/-xes/-zes/-ches/-shes→strip es, -s→strip s).
    # For truly irregular plurals in conventions, use @[Operation(SaveX)] annotation.
    # Example: {"Statuses" => "Status", "Addresses" => "Address"}
    setting inflect_overrides : Hash(String, String) = {} of String => String

    # operationId style for auto-generated IDs: "snake_case" or "camel_case" (default).
    # Override per-operation with @[LuckySwagger::Endpoint(operation_id: "myOp")].
    setting operation_id_style : String = "camel_case"
  end
end
