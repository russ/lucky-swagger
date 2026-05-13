struct StreamSerializer < BaseSerializer
  swagger_fields do
    # UUID-formatted string field — demonstrates ScalarFormat-style via field macro
    field stream_id    : String, format: "uuid", example: "550e8400-e29b-41d4-a716-446655440000"
    field title        : String, max_length: 100, min_length: 1
    field status       : String, enum: ["live", "offline", "scheduled"]
    property viewer_count  : Int32
    property thumbnail_url : String?
    property started_at    : Time?
    property ended_at      : Time?
    property stream_url    : String?
    property is_public     : Bool
  end
end
