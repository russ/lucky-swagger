module OperationIdScenario
  module Widgets
    class Index < ScenarioAction
      get "/scenarios/operation-id/widgets" do
        plain_text "ok"
      end
    end

    class Show < ScenarioAction
      get "/scenarios/operation-id/widgets/:id" do
        plain_text "ok"
      end
    end

    @[LuckySwagger::Endpoint(operation_id: "createWidgetExplicit")]
    class Create < ScenarioAction
      post "/scenarios/operation-id/widgets" do
        plain_text "ok"
      end
    end
  end
end
