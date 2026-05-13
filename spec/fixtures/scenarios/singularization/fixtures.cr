# SaveX operations live inside the scenario module so the namespace-relative
# fallback (SingularizationScenario::SaveX) finds them without polluting top level.
module SingularizationScenario
  class SaveBaby
    include LuckySwagger::Documentable

    swagger_fields do
      property name : String
      property birth_date : String?
    end
  end

  class SaveStatus
    include LuckySwagger::Documentable

    swagger_fields do
      property label : String
      property active : Bool
    end
  end

  class SaveWatch
    include LuckySwagger::Documentable

    swagger_fields do
      property serial : String
      property brand : String?
    end
  end

  class SaveAddress
    include LuckySwagger::Documentable

    swagger_fields do
      property street : String
      property city : String
    end
  end

  module Babies
    class Create < ScenarioAction
      post "/scenarios/singularization/babies" do
        plain_text "ok"
      end
    end

    class Update < ScenarioAction
      put "/scenarios/singularization/babies/:id" do
        plain_text "ok"
      end
    end
  end

  module Statuses
    class Create < ScenarioAction
      post "/scenarios/singularization/statuses" do
        plain_text "ok"
      end
    end
  end

  module Watches
    class Create < ScenarioAction
      post "/scenarios/singularization/watches" do
        plain_text "ok"
      end
    end
  end

  module Addresses
    class Create < ScenarioAction
      post "/scenarios/singularization/addresses" do
        plain_text "ok"
      end
    end
  end
end
