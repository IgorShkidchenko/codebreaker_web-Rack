# frozen_string_literal: true

module RackHelper
  LAYOUT_PATH = File.expand_path('../views/layouts/layout.html.haml', __dir__)

  def session_contain?(request, key)
    request.session.key?(key)
  end

  def redirect_to(page)
    Rack::Response.new { |response| response.redirect(page) }
  end

  def show_page(template)
    Rack::Response.new(render_layout { render_page_file(template) })
  end

  def partial(template)
    render_page_file(template)
  end

  private

  def render_layout
    Haml::Engine.new(File.read(LAYOUT_PATH)).render(binding)
  end

  def render_page_file(template)
    path = File.expand_path("../../views/#{template}.html.haml", __FILE__)
    Haml::Engine.new(File.read(path)).render(binding)
  end
end
