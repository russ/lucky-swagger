module LuckySwagger
  # Standard pagination envelope registered in components/schemas.
  struct PaginationSchema
    include JSON::Serializable

    property next_page : String?
    property previous_page : String?
    property total_items : Int32
    property total_pages : Int32
    property per_page : Int32
  end

  # Standard error response registered in components/schemas.
  struct ErrorSchema
    include JSON::Serializable

    property message : String
    property param : String?
    property details : String?
  end
end
