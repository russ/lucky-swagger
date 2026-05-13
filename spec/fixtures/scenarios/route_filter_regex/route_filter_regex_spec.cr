require "../scenarios_helper"
require "./fixtures"

describe "S-22: route_filter_regex" do
  it "includes only routes matching the scenario prefix" do
    paths = Scenarios.generate("route-filter-regex")[:paths].not_nil!

    paths.has_key?("/scenarios/route-filter-regex/included").should be_true
    paths.has_key?("/scenarios/route-filter-regex/also").should be_true
    paths.has_key?("/elsewhere/route-filter-regex/skipped").should be_false
  end
end
