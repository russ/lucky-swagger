module TagConfigScenario
  # Defaults: ["Api", "Actions", "V1", "V2"] stripped, " > " separator,
  # "default" fallback. With our wrapping namespace 'TagConfigScenario'
  # plus 'Frontend::Users', expected default tag is
  # "TagConfigScenario > Frontend > Users" (none of these are stripped).
  module Frontend
    module Users
      class Index < ScenarioAction
        get "/scenarios/tag-config/frontend/users" do
          plain_text "ok"
        end
      end
    end
  end

  # An action that ends up fully stripped under aggressive prefix config
  # (will be exercised in the spec by overriding tag_strip_prefixes).
  module Api
    module V1
      class Status < ScenarioAction
        get "/scenarios/tag-config/api/v1/status" do
          plain_text "ok"
        end
      end
    end
  end
end
