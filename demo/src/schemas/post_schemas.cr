struct PostCreateRequest
  include JSON::Serializable

  property title : String
  property body : String
  property status : String?
  property tags : Array(String)?
end

struct PostUpdateRequest
  include JSON::Serializable

  property title : String?
  property body : String?
  property status : String?
  property tags : Array(String)?
end
