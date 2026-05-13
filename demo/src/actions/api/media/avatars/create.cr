@[LuckySwagger::Endpoint(
  summary: "Upload avatar",
  description: "Upload a new profile avatar. Accepts JPEG, PNG, or WebP up to 5MB. Hosted on the upload CDN, not the main API server.",
  servers: [{url: "https://upload.example.com", description: "Upload CDN"}],
)]
@[LuckySwagger::HeaderParam(name: "X-Request-ID", type: String, required: false, description: "Idempotency key — safe to retry with the same key")]
@[LuckySwagger::RequestBody(multipart: {file: File, alt_text: String})]
@[LuckySwagger::Response(201, schema: AvatarUploadResponse, description: "Avatar uploaded and processed")]
@[LuckySwagger::Response(413, schema: LuckySwagger::ErrorSchema, description: "File exceeds 5MB limit")]
@[LuckySwagger::Response(422, schema: LuckySwagger::ErrorSchema, description: "Unsupported file type")]
class Api::Media::Avatars::Create < ApiAction
  post "/api/media/avatars" do
    plain_text "ok"
  end
end
