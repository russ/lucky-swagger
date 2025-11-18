require "lucky"
require "lucky-swagger"

# Require all application files
require "./actions/**"
require "./app_server"
require "./errors/**"

# Configure Lucky
Lucky::Server.configure do |settings|
  settings.secret_key_base = "demo_secret_key_base_change_in_production"
  settings.host = "0.0.0.0"
  settings.port = 5000
end

# Start the server
puts "Starting demo server on http://localhost:5000"
puts "SwaggerUI available at http://localhost:5000/api-docs"
puts ""

AppServer.new.listen
