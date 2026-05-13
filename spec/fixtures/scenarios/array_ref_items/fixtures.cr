struct ArrayItemTagSerializer
  include LuckySwagger::Documentable

  swagger_fields do
    property id : Int64
    property label : String
  end
end

struct ArrayItemPostSerializer
  include LuckySwagger::Documentable

  swagger_fields do
    property id : Int64
    property tags : Array(ArrayItemTagSerializer)
    property tag_ids : Array(Int64)
    property labels : Array(String)
    property scores : Array(Float64)
    property maybe_tags : Array(ArrayItemTagSerializer)?
  end
end

module ArrayRefItemsScenario
  @[LuckySwagger::Response(200, serializer: ArrayItemTagSerializer)]
  class ShowTag < ScenarioAction
    get "/scenarios/array-ref-items/tags/:id" do
      plain_text "ok"
    end
  end

  @[LuckySwagger::Response(200, serializer: ArrayItemPostSerializer)]
  class ShowPost < ScenarioAction
    get "/scenarios/array-ref-items/posts/:id" do
      plain_text "ok"
    end
  end
end
