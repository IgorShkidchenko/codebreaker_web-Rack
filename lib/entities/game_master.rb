# frozen_string_literal: true

class GameMaster
  attr_reader :game, :result

  include Codebreaker::Uploader
  include RackHelper

  EMPTY_SPACE_IN_RESULT = 'x'
  GUESS_MARKS = {
    success: Codebreaker::Game::GUESS_PLACE,
    primary: Codebreaker::Game::GUESS_PRESENCE,
    danger: EMPTY_SPACE_IN_RESULT
  }.freeze

  def initialize(request)
    @request = request
  end

  def update_game_data
    @game = @request.session[:game]
    return unless session_contain?(@request, :result)

    @result = @request.session[:result]
    fill_empty_space_in_result if @result.size < Codebreaker::Game::CODE_SIZE
  end

  def registrate_new_game
    user = Codebreaker::User.new(@request.params['player_name'])
    difficulty = Codebreaker::Difficulty.find(@request.params['level'])
    return redirect_to(CodebreakerRack::URLS[:index]) unless registration_data_valid?(difficulty, user)

    @request.session[:game] = Codebreaker::Game.new(difficulty, user)
    redirect_to(CodebreakerRack::URLS[:game])
  end

  def show_hint
    @game.hint
    redirect_to(CodebreakerRack::URLS[:game])
  end

  def start_round
    guess = validate_guess
    return win if @game.win?(guess)
    return lose if @game.lose?(guess)

    @request.session[:result] = @game.start_round(guess) if validate_guess
    redirect_to(CodebreakerRack::URLS[:game])
  end

  private

  def registration_data_valid?(difficulty, user)
    user.valid? && difficulty
  end

  def validate_guess
    guess = Codebreaker::Guess.new(@request.params['guess'])
    guess.as_array_of_numbers if guess.valid?
  end

  def fill_empty_space_in_result
    @result += Array.new(Codebreaker::Game::CODE_SIZE - @result.size) { GUESS_MARKS[:danger] }
  end

  def win
    save_to_db(@game.to_h)
    @request.session[:game_over] = true
    redirect_to(CodebreakerRack::URLS[:win])
  end

  def lose
    @request.session[:game_over] = true
    redirect_to(CodebreakerRack::URLS[:lose])
  end
end
