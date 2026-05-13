@[LuckySwagger::Endpoint(
  summary: "List streams",
  description: "Returns a paginated list of streams. Filter by status to find live or upcoming streams.",
)]
@[LuckySwagger::Response(200, serializer: StreamSerializer, collection: true, description: "Paginated stream list")]
class Api::Frontend::Streams::Index < ApiAction
  param status   : String?
  param page     : Int32 = 1
  param per_page : Int32 = 20
  swagger_enum status, ["live", "offline", "scheduled"]

  get "/api/frontend/streams" do
    plain_text "ok"
  end
end
