# frozen_string_literal: true

require_relative 'autoload'

use Rack::Reloader
use Rack::Static, urls: ['/public', '/node_modules'], root: './'
use Rack::Session::Cookie, key: 'rack.session', secret: 'secret'

run CodebreakerRack
