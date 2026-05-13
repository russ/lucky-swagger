@[LuckySwagger::Endpoint(
  summary: "Export posts as CSV",
  description: "Downloads all visible posts as a CSV file. Useful for bulk analysis or migration. Returns 204 if there are no posts to export.",
)]
@[LuckySwagger::Response(200, content_type: "text/csv", description: "CSV file with post data")]
@[LuckySwagger::Response(204)]
class Api::Exports::Posts < ApiAction
  param status : String?
  swagger_enum status, ["published", "draft", "archived"]

  get "/api/exports/posts.csv" do
    plain_text "ok"
  end
end
