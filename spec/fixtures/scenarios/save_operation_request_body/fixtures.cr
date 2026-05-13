# SaveThing lives at top level so the convention can find it
# (Foo::Things::Create looks for ::SaveThing).
class SaveThing
  include LuckySwagger::Documentable

  swagger_fields do
    property name : String
    property quantity : Int32?
  end
end

# An explicitly-annotated operation that doesn't follow Save<Singular>
# naming — the action will reference it via @[Operation(...)].
class CustomThingyOperation
  include LuckySwagger::Documentable

  swagger_fields do
    property title : String
    property archived : Bool?
  end
end

# A request-body schema for the explicit RequestBody annotation override case.
struct SaveOperationScenarioRequestOverride
  include JSON::Serializable

  property override_field : String
end

module SaveOperationRequestBodyScenario
  module Things
    # Convention path: Things::Create => SaveThing (top-level)
    class Create < ScenarioAction
      post "/scenarios/save-operation-request-body/things" do
        plain_text "ok"
      end
    end

    # Convention also covers Update
    class Update < ScenarioAction
      put "/scenarios/save-operation-request-body/things/:id" do
        plain_text "ok"
      end
    end
  end

  # Annotation path: explicit Operation pointer to a non-conventional class
  @[LuckySwagger::Operation(CustomThingyOperation)]
  class AnnotationBound < ScenarioAction
    post "/scenarios/save-operation-request-body/annotation-bound" do
      plain_text "ok"
    end
  end

  # Override priority: RequestBody beats Operation beats Convention
  @[LuckySwagger::RequestBody(schema: SaveOperationScenarioRequestOverride)]
  @[LuckySwagger::Operation(CustomThingyOperation)]
  class OverridePriority < ScenarioAction
    post "/scenarios/save-operation-request-body/override" do
      plain_text "ok"
    end
  end
end
