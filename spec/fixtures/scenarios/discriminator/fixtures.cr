struct EventCreated
  include JSON::Serializable
  property kind : String
  property resource_id : Int64
end

struct EventDeleted
  include JSON::Serializable
  property kind : String
  property resource_id : Int64
  property deleted_at : String
end

module DiscriminatorScenario
  # oneOf with discriminator property name
  @[LuckySwagger::Response(200, one_of: [EventCreated, EventDeleted], discriminator: "kind")]
  class EventShow < ScenarioAction
    get "/scenarios/discriminator/events/:id" do
      plain_text "ok"
    end
  end

  # anyOf with discriminator
  @[LuckySwagger::Response(200, any_of: [EventCreated, EventDeleted], discriminator: "kind")]
  class EventAny < ScenarioAction
    get "/scenarios/discriminator/events/:id/any" do
      plain_text "ok"
    end
  end

  # allOf without discriminator (discriminator not meaningful for allOf)
  @[LuckySwagger::Response(200, all_of: [EventCreated, EventDeleted])]
  class EventAll < ScenarioAction
    get "/scenarios/discriminator/events/:id/all" do
      plain_text "ok"
    end
  end
end
