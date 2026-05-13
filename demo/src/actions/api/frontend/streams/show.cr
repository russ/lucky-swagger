@[LuckySwagger::Response(200, serializer: StreamSerializer, description: "Stream details")]
@[LuckySwagger::Response(404, schema: LuckySwagger::ErrorSchema, description: "Stream not found")]
class Api::Frontend::Streams::Show < ApiAction
  get "/api/frontend/streams/:id" do
    plain_text "ok"
  end
end
