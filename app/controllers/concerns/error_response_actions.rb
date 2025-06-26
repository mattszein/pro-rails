module ErrorResponseActions
  def route_not_found
    render_error("Page Not Found")
  end

  def render_error(message)
    @message = message
    error = {error: {errors: [{domain: "global", reason: "notFound", message: message}], code: 404, message: message}}.to_json
    respond_to do |format|
      format.html { render template: "/rescues/error", status: :internal_server_error }
      format.json { render json: error, status: :internal_server_error }
    end
  end
end
