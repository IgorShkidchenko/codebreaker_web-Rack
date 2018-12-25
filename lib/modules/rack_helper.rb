# frozen_string_literal: true

module RackHelper
  def session_contain?(request, key)
    request.session.key?(key)
  end

  def redirect_to(page)
    Rack::Response.new { |response| response.redirect(page) }
  end

  def show_page(template)
    path = File.expand_path("../../views/#{template}.html.haml", __FILE__)
    page = Haml::Engine.new(File.read(path)).render(binding)
    Rack::Response.new(page)
  end
end
