# EF-10: custom scalar type annotated with ScalarFormat
@[LuckySwagger::ScalarFormat(type: "string", format: "uuid")]
struct ScenarioUUID
  include JSON::Serializable
  property value : String

  def initialize(@value)
  end
end

struct AssetSerializer
  include LuckySwagger::Documentable

  swagger_fields do
    @[LuckySwagger::FieldMeta(example: "550e8400-e29b-41d4-a716-446655440000")]
    property id : ScenarioUUID

    property name : String
    property optional_ref : ScenarioUUID?
  end
end

module ExternalDocsAndFormatsScenario
  # EF-9: operation with externalDocs (url + description)
  @[LuckySwagger::Endpoint(external_docs: {url: "https://docs.example.com/assets", description: "Asset API docs"})]
  @[LuckySwagger::Response(200, serializer: AssetSerializer)]
  class AssetShow < ScenarioAction
    get "/scenarios/external-docs-and-formats/assets/:id" do
      plain_text "ok"
    end
  end

  # EF-9: externalDocs url only (no description)
  @[LuckySwagger::Endpoint(external_docs: {url: "https://docs.example.com/simple"})]
  class SimpleAction < ScenarioAction
    get "/scenarios/external-docs-and-formats/simple" do
      plain_text "ok"
    end
  end

  # No externalDocs — confirms no bleed-through
  class NoDocsAction < ScenarioAction
    get "/scenarios/external-docs-and-formats/no-docs" do
      plain_text "ok"
    end
  end
end
