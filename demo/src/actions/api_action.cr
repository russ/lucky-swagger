# Base action for all API endpoints
abstract class ApiAction < Lucky::Action
  # All API actions accept JSON and return JSON
  accepted_formats [:json], default: :json
end
