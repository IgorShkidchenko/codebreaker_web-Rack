# frozen_string_literal: true

class ValidateRequest
  include RackHelper

  ERROR_404_PATH = 'errors/404'

  def initialize(app)
    @app = app
  end

  def call(env)
    @request = Rack::Request.new(env)
    return Rack::Response.new(render_page_file(ERROR_404_PATH), 404) unless valid_request?

    @app.call(env)
  end

  private

  def valid_request?
    CodebreakerRack::URLS.value?(@request.path)
  end
end
