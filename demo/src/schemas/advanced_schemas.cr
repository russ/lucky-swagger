# --- OAuth / token endpoint polymorphic response shapes ---

struct AccessTokenShape
  include JSON::Serializable
  property grant_type : String  # discriminator value: "access"
  property access_token : String
  property token_type : String
  property expires_in : Int32
  property scope : String
end

struct RefreshTokenShape
  include JSON::Serializable
  property grant_type : String  # discriminator value: "refresh"
  property refresh_token : String
  property token_type : String
  property expires_in : Int32
end

struct TokenRequest
  include JSON::Serializable
  property grant_type : String  # "password" | "refresh_token" | "client_credentials"
  property username : String?
  property password : String?
  property refresh_token : String?
  property client_id : String
  property scope : String?
end

# --- Media upload ---

struct AvatarUploadResponse
  include JSON::Serializable
  property url : String
  property cdn_url : String
  property width : Int32
  property height : Int32
  property file_size : Int64
end

# --- SaveStream: top-level operation — auto-bound by convention to
#     Api::Frontend::Streams::Create and Api::Frontend::Streams::Update ---

class SaveStream
  include LuckySwagger::Documentable

  swagger_fields do
    field title       : String,  max_length: 100, min_length: 1, example: "Saturday Night Stream"
    field status      : String,  enum: ["scheduled", "offline"], default: "offline"
    field description : String?, max_length: 2000
    field category    : String?, enum: ["gaming", "music", "talk", "irl", "art"]
  end
end
