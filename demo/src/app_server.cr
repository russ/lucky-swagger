class AppServer < Lucky::BaseAppServer
  def middleware : Array(HTTP::Handler)
    [
      # Add the LuckySwagger WebHandler to serve SwaggerUI
      # This will serve SwaggerUI at http://localhost:5000/api-docs
      # and YAML files from the ./swagger directory
      LuckySwagger::Handlers::WebHandler.new(
        swagger_url: "/api-docs",
        folder: "./swagger"
      ),
      Lucky::HttpMethodOverrideHandler.new,
      Lucky::LogHandler.new,
      Lucky::ErrorHandler.new(action: Errors::Show),
      Lucky::RouteHandler.new,
    ] of HTTP::Handler
  end

  def protocol
    "http"
  end

  def listen
    server.listen(host, port, reuse_port: false)
  end
end
