module HumanizedSummaryScenario
  module Widgets
    class Index < ScenarioAction
      get "/scenarios/humanized-summary/widgets" do
        plain_text "ok"
      end
    end

    class Show < ScenarioAction
      get "/scenarios/humanized-summary/widgets/:id" do
        plain_text "ok"
      end
    end

    class Create < ScenarioAction
      post "/scenarios/humanized-summary/widgets" do
        plain_text "ok"
      end
    end

    class Update < ScenarioAction
      put "/scenarios/humanized-summary/widgets/:id" do
        plain_text "ok"
      end
    end

    class Destroy < ScenarioAction
      delete "/scenarios/humanized-summary/widgets/:id" do
        plain_text "ok"
      end
    end

    class BulkArchive < ScenarioAction
      post "/scenarios/humanized-summary/widgets/bulk-archive" do
        plain_text "ok"
      end
    end
  end

  @[LuckySwagger::Endpoint(summary: "My custom summary")]
  class CustomAction < ScenarioAction
    get "/scenarios/humanized-summary/custom" do
      plain_text "ok"
    end
  end
end
