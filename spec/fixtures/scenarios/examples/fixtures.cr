struct ArticleSerializer
  include LuckySwagger::Documentable

  swagger_fields do
    @[LuckySwagger::FieldMeta(example: 42)]
    property id : Int64

    @[LuckySwagger::FieldMeta(example: "Hello World")]
    property title : String

    @[LuckySwagger::FieldMeta(example: "draft")]
    property status : String?

    property view_count : Int32
  end
end

module ExamplesScenario
  # Response-level example via serializer
  @[LuckySwagger::Response(200, serializer: ArticleSerializer, example: {id: 42, title: "Hello World", status: "draft", view_count: 0})]
  class ArticleShow < ScenarioAction
    get "/scenarios/examples/articles/:id" do
      plain_text "ok"
    end
  end

  # Response-level example via schema ref
  @[LuckySwagger::Response(200, schema: ArticleSerializer::SwaggerSchema, example: {id: 1, title: "Test"})]
  class ArticleShowAlt < ScenarioAction
    get "/scenarios/examples/articles/:id/alt" do
      plain_text "ok"
    end
  end

  # Non-JSON response with example
  @[LuckySwagger::Response(200, content_type: "text/plain", example: "pong")]
  class Ping < ScenarioAction
    get "/scenarios/examples/ping" do
      plain_text "ok"
    end
  end

  # No example — baseline to confirm nothing bleeds through
  @[LuckySwagger::Response(200, serializer: ArticleSerializer)]
  class ArticleNoExample < ScenarioAction
    get "/scenarios/examples/articles/:id/no-example" do
      plain_text "ok"
    end
  end
end
