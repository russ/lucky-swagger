@[LuckySwagger::Endpoint(
  summary: "Analytics overview",
  description: "Aggregated view/revenue analytics for the selected period. Office-only endpoint.",
  external_docs: {url: "https://docs.example.com/analytics", description: "Analytics API reference"},
)]
@[LuckySwagger::Response(200, serializer: AnalyticsSerializer, description: "Aggregated analytics")]
class Api::Office::Analytics::Overview < ApiAction
  param period : String = "week"
  swagger_enum period, ["day", "week", "month", "all_time"]

  get "/api/office/analytics/overview" do
    plain_text "ok"
  end
end
