module LuckySwagger
  # Represents a single OAuth2 flow (authorizationCode, clientCredentials, etc.)
  # Fields serialize with OpenAPI-required camelCase keys.
  struct OAuth2Flow
    include YAML::Serializable

    @[YAML::Field(key: "authorizationUrl")]
    property authorization_url : String?

    @[YAML::Field(key: "tokenUrl")]
    property token_url : String?

    @[YAML::Field(key: "refreshUrl")]
    property refresh_url : String?

    property scopes : Hash(String, String)

    def initialize(@scopes, @authorization_url = nil, @token_url = nil, @refresh_url = nil)
    end
  end

  # Represents an OAuth2 security scheme with one or more named flows.
  # Usage:
  #   settings.oauth2_schemes = {
  #     "oauth2" => LuckySwagger::OAuth2Scheme.new(
  #       flows: {
  #         "authorizationCode" => LuckySwagger::OAuth2Flow.new(
  #           scopes:            {"read" => "Read access", "write" => "Write access"},
  #           authorization_url: "https://example.com/oauth/authorize",
  #           token_url:         "https://example.com/oauth/token"
  #         )
  #       }
  #     )
  #   }
  struct OAuth2Scheme
    include YAML::Serializable

    property type : String
    property flows : Hash(String, OAuth2Flow)

    def initialize(@flows, @type = "oauth2")
    end
  end

  # Standard pagination envelope registered in components/schemas.
  struct PaginationSchema
    include JSON::Serializable

    property next_page : String?
    property previous_page : String?
    property total_items : Int32
    property total_pages : Int32
    property per_page : Int32
  end

  # Standard error response registered in components/schemas.
  struct ErrorSchema
    include JSON::Serializable

    property message : String
    property param : String?
    property details : String?
  end
end
