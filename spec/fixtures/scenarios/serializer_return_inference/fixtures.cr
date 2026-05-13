struct WidgetSerializer
  include LuckySwagger::Documentable

  swagger_fields do
    property id : Int64
    property name : String
    property color : String?
  end
end

# A second serializer for the override-priority case.
struct WidgetExplicitSerializer
  include LuckySwagger::Documentable

  swagger_fields do
    property id : Int64
    property override : Bool
  end
end

module SerializerReturnInferenceScenario
  module Widgets
    # Show: convention infers WidgetSerializer => 200
    class Show < ScenarioAction
      get "/scenarios/serializer-return-inference/widgets/:id" do
        plain_text "ok"
      end
    end

    # Create: convention infers WidgetSerializer => 201 + auto-422
    class Create < ScenarioAction
      post "/scenarios/serializer-return-inference/widgets" do
        plain_text "ok"
      end
    end

    # Update: convention infers WidgetSerializer => 200 + auto-422
    class Update < ScenarioAction
      put "/scenarios/serializer-return-inference/widgets/:id" do
        plain_text "ok"
      end
    end

    # Delete: NOT covered by IR-3; default 204 should apply
    class Delete < ScenarioAction
      delete "/scenarios/serializer-return-inference/widgets/:id" do
        plain_text "ok"
      end
    end

    # Override: explicit Response annotation beats convention
    @[LuckySwagger::Response(200, serializer: WidgetExplicitSerializer)]
    class ShowOverridden < ScenarioAction
      get "/scenarios/serializer-return-inference/widgets/:id/overridden" do
        plain_text "ok"
      end
    end
  end

  # No matching serializer => fall through to default
  module Orphans
    class Show < ScenarioAction
      get "/scenarios/serializer-return-inference/orphans/:id" do
        plain_text "ok"
      end
    end
  end
end
