struct UserCreateRequest
  include JSON::Serializable

  property email : String
  property password : String
  property name : String
  property username : String
  property bio : String?
  property role : String?
end

struct UserUpdateRequest
  include JSON::Serializable

  property email : String?
  property name : String?
  property username : String?
  property bio : String?
  property avatar_url : String?
  property role : String?
  property active : Bool?
end
