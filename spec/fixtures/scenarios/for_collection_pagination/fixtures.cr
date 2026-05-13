struct GadgetSerializer
  include LuckySwagger::Documentable

  swagger_fields do
    property id : Int64
    property name : String
  end
end

module ForCollectionPaginationScenario
  module Gadgets
    # Index: convention infers GadgetSerializer wrapped in collection (items + pagination)
    class Index < ScenarioAction
      get "/scenarios/for-collection-pagination/gadgets" do
        plain_text "ok"
      end
    end
  end

  # Index without a matching serializer => default response (no inference)
  module Mysteries
    class Index < ScenarioAction
      get "/scenarios/for-collection-pagination/mysteries" do
        plain_text "ok"
      end
    end
  end
end
