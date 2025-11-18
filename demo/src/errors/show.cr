class Errors::Show < Lucky::ErrorAction
  default_format :json

  def default_render(error : Exception) : Lucky::Response
    if error.is_a?(Lucky::RouteNotFoundError)
      error_json "Not found", status: 404
    else
      error_json error.message || "An error occurred", status: 500
    end
  end

  def report(error : Exception) : Nil
    # In production, you would log errors here
    # For demo purposes, we'll just print to stderr
    STDERR.puts "Error: #{error.message}"
    STDERR.puts error.backtrace.join("\n") if error.backtrace?
  end

  private def error_json(message : String, status : Int32) : Lucky::Response
    json({error: message}, status: status)
  end
end
