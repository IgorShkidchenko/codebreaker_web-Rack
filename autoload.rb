# frozen_string_literal: true

require 'i18n'
require 'haml'
require 'codebreaker'
require_relative 'config/i18n'
require_relative 'lib/modules/rack_helper'
require_relative 'lib/middlewares/validate_request'
require_relative 'lib/entities/codebreaker_rack'
require_relative 'lib/entities/game_master'
