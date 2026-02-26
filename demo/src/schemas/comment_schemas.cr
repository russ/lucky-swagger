struct CommentCreateRequest
  include JSON::Serializable

  property body : String
  property parent_id : Int64?
end
