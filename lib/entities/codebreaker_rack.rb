# frozen_string_literal: true

class CodebreakerRack
  include Codebreaker::Uploader
  include RackHelper

  PAGES = {
    menu: 'menu',
    stats: 'stats',
    rules: 'rules',
    game: 'game',
    win: 'win',
    lose: 'lose'
  }.freeze

  URLS = {
    index: '/',
    stats: "/#{PAGES[:stats]}",
    rules: "/#{PAGES[:rules]}",
    registration: '/registration',
    win: "/#{PAGES[:win]}",
    lose: "/#{PAGES[:lose]}",
    show_hint: '/show_hint',
    game: "/#{PAGES[:game]}",
    make_guess: '/make_guess'
  }.freeze

  ALL_PARTIALS = {
    game_info: '/partials/game_info',
    game_over_buttons: '/partials/game_over_buttons',
    home_button: '/partials/home_button',
    assets: '/partials/assets_load'
  }.freeze

  def self.call(env)
    new(env).response.finish
  end

  def initialize(env)
    @request = Rack::Request.new(env)
    @act = GameMaster.new(@request)
  end

  def response
    session_contain?(@request, :game) ? active_game_phase : absent_game_phase
  end

  def show_stats
    load_db.sort_by { |user| [user[:all_attempts], -user[:left_attempts], -user[:left_hints]] }
  end

  def session_destroy
    @request.session.clear
  end

  private

  def absent_game_phase
    case @request.path
    when URLS[:index] then show_page(PAGES[:menu])
    when URLS[:stats] then show_page(PAGES[:stats])
    when URLS[:rules] then show_page(PAGES[:rules])
    when URLS[:registration] then @act.registrate_new_game
    else redirect_to(URLS[:index])
    end
  end

  def active_game_phase
    @act.update_game_data
    case @request.path
    when URLS[:game] then show_page(PAGES[:game])
    when URLS[:show_hint] then @act.show_hint
    when URLS[:make_guess] then @act.start_round
    when URLS[:win] then check_game_over(PAGES[:win])
    when URLS[:lose] then check_game_over(PAGES[:lose])
    else redirect_to(URLS[:game])
    end
  end

  def check_game_over(page)
    session_contain?(@request, :game_over) ? show_page(page) : redirect_to(URLS[:game])
  end
end
