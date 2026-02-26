struct PostSerializer < BaseSerializer
  swagger_fields do
    property id : Int64
    property title : String
    property body : String
    property slug : String
    property status : String
    property author_id : Int64
    property author_name : String
    property tags : Array(String)
    property comments_count : Int32
    property likes_count : Int32
    property published_at : Time?
    property created_at : Time
    property updated_at : Time
  end
end
