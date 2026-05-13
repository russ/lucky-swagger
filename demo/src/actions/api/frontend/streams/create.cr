# Request body inferred by convention: Streams::Create → SaveStream at top level.
# No @[RequestBody] annotation needed.
class Api::Frontend::Streams::Create < ApiAction
  post "/api/frontend/streams" do
    plain_text "ok"
  end
end
