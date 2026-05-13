struct AnalyticsSerializer < BaseSerializer
  swagger_fields do
    property total_views    : Int64
    property unique_viewers : Int32
    property total_streams  : Int32
    field revenue           : Float64, minimum: 0.0, example: 1234.56
    field conversion_rate   : Float64, minimum: 0.0, maximum: 100.0
    field top_country       : String?, example: "US"
    field period            : String,  enum: ["day", "week", "month", "all_time"]
  end
end
