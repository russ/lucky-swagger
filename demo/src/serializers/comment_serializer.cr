struct CommentSerializer < BaseSerializer
  swagger_fields do
    property id : Int64
    property body : String
    property author_id : Int64
    property author_name : String
    property post_id : Int64
    property parent_id : Int64?
    property likes_count : Int32
    property deleted : Bool
    property created_at : Time
    property updated_at : Time
  end
end
