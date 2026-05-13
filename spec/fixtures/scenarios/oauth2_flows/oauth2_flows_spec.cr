require "yaml"
require "../scenarios_helper"
require "./fixtures"

private def generate_yaml
  filter = Regex.new("^/scenarios/oauth2-flows/")
  spec = nil
  LuckySwagger.temp_config(
    include_routes: filter,
    oauth2_schemes: {
      "oauth2" => LuckySwagger::OAuth2Scheme.new(
        flows: {
          "authorizationCode" => LuckySwagger::OAuth2Flow.new(
            scopes:            {"read" => "Read access", "write" => "Write access"},
            authorization_url: "https://example.com/oauth/authorize",
            token_url:         "https://example.com/oauth/token"
          ),
          "clientCredentials" => LuckySwagger::OAuth2Flow.new(
            scopes:    {"admin" => "Admin access"},
            token_url: "https://example.com/oauth/token"
          ),
        }
      ),
    },
    security_schemes: {"bearerAuth" => {"type" => "http", "scheme" => "bearer"}}
  ) do
    spec = LuckySwagger::OpenApiGenerator.generate_open_api
  end
  YAML.parse(spec.not_nil!.to_yaml)
end

private def security_schemes
  generate_yaml["components"]["securitySchemes"].as_h
end

describe "S-16: oauth2_flows" do
  describe "OAuth2 scheme structure" do
    it "registers the oauth2 scheme in components/securitySchemes" do
      security_schemes.has_key?(YAML::Any.new("oauth2")).should be_true
    end

    it "emits type: oauth2" do
      security_schemes[YAML::Any.new("oauth2")]["type"].as_s.should eq("oauth2")
    end

    it "emits the flows key" do
      security_schemes[YAML::Any.new("oauth2")].as_h.has_key?(YAML::Any.new("flows")).should be_true
    end
  end

  describe "authorizationCode flow" do
    it "emits authorizationUrl with camelCase key" do
      flow = security_schemes[YAML::Any.new("oauth2")]["flows"]["authorizationCode"]
      flow.as_h.has_key?(YAML::Any.new("authorizationUrl")).should be_true
      flow["authorizationUrl"].as_s.should eq("https://example.com/oauth/authorize")
    end

    it "emits tokenUrl with camelCase key" do
      flow = security_schemes[YAML::Any.new("oauth2")]["flows"]["authorizationCode"]
      flow["tokenUrl"].as_s.should eq("https://example.com/oauth/token")
    end

    it "emits scopes" do
      flow = security_schemes[YAML::Any.new("oauth2")]["flows"]["authorizationCode"]
      scopes = flow["scopes"].as_h
      scopes.has_key?(YAML::Any.new("read")).should be_true
      scopes.has_key?(YAML::Any.new("write")).should be_true
    end
  end

  describe "clientCredentials flow" do
    it "emits clientCredentials flow" do
      flows = security_schemes[YAML::Any.new("oauth2")]["flows"].as_h
      flows.has_key?(YAML::Any.new("clientCredentials")).should be_true
    end

    it "does not emit authorizationUrl for clientCredentials" do
      flow = security_schemes[YAML::Any.new("oauth2")]["flows"]["clientCredentials"]
      flow.as_h.has_key?(YAML::Any.new("authorizationUrl")).should be_false
    end
  end

  describe "coexistence with simple schemes" do
    it "also registers the simple bearerAuth scheme" do
      security_schemes.has_key?(YAML::Any.new("bearerAuth")).should be_true
    end

    it "bearerAuth has flat string values" do
      security_schemes[YAML::Any.new("bearerAuth")]["type"].as_s.should eq("http")
    end
  end
end
