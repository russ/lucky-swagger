struct UserSerializer < BaseSerializer
  swagger_fields do
    property id : Int64
    property email : String
    property name : String
    property username : String
    property bio : String?
    property avatar_url : String?
    property active : Bool
    property role : String
    property posts_count : Int32
    property created_at : Time
    property updated_at : Time
  end
end
