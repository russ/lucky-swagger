struct ConstrainedPostSerializer
  include LuckySwagger::Documentable

  swagger_fields do
    # Plain property — no constraints (IR-9: required by nilability)
    property id : Int64

    # IR-10: enum constraint + IR-11: default value
    field status : String, enum: ["draft", "published", "archived"], default: "draft"

    # IR-12: string size constraints
    field title : String, max_length: 200, min_length: 1

    # IR-12: format constraint on string
    field author_email : String, format: "email"

    # IR-11: numeric range + default
    field priority : Int32, minimum: 1, maximum: 5, default: 3

    # format on nullable string field
    field published_at : String?, format: "date-time"

    # float range constraints
    field score : Float64, minimum: 0.0, maximum: 100.0

    # optional plain property — no constraints
    property body : String?
  end
end

module FieldConstraintsScenario
  @[LuckySwagger::Response(200, serializer: ConstrainedPostSerializer)]
  class ConstrainedPostShow < ScenarioAction
    get "/scenarios/field-constraints/posts/:id" do
      plain_text "ok"
    end
  end
end
