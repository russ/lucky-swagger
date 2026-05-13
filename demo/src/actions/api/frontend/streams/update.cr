# Request body inferred by convention: Streams::Update → SaveStream at top level.
class Api::Frontend::Streams::Update < ApiAction
  put "/api/frontend/streams/:id" do
    plain_text "ok"
  end
end
