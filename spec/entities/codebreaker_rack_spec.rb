# frozen_string_literal: true

OUTER_APP = Rack::Builder.parse_file('./config.ru').first

RSpec.describe CodebreakerRack do
  def app
    OUTER_APP
  end

  let(:difficulty_double) { instance_double('Difficulty', level: Codebreaker::Difficulty::DIFFICULTIES[:simple]) }
  let(:user_double) { instance_double('User', name: valid_name) }
  let(:game) { Codebreaker::Game.new(difficulty_double, user_double) }

  let(:valid_name) { 'a' * Codebreaker::User::VALID_NAME_SIZE.min }
  let(:wrong_guess) { '1234' }
  let(:valid_code) { [1, 6, 6, 6] }

  describe 'when open unknown url receive 404 error' do
    let(:unknow_url) { '/unknown_url' }
    let(:response) { get unknow_url }

    it { expect(response.status).to eq 404 }
    it { expect(response.body).to include I18n.t('error_404') }
  end

  describe 'when open allowed pages with absent game phase' do
    context 'when open index' do
      let(:response) { get CodebreakerRack::URLS[:index] }

      it { expect(response).to be_ok }
      it { expect(response.body).to include I18n.t('menu_page.name_form.label_name') }
    end

    context 'when open rules' do
      let(:response) { get CodebreakerRack::URLS[:rules] }

      it { expect(response).to be_ok }
      it { expect(response.body).to include I18n.t('rules_page_rules') }
    end

    context 'when open stats' do
      let(:response) { get CodebreakerRack::URLS[:stats] }

      it { expect(response).to be_ok }
      it { expect(response.body).to include I18n.t('stats_page.top_of_players') }
    end
  end

  describe 'when post registration with absent game phase' do
    context 'when valid data must to be redirected to game page with NOT nil game session' do
      let(:response) do
        post CodebreakerRack::URLS[:registration], player_name: valid_name, level: difficulty_double.level[:level]
      end

      before do
        response
        follow_redirect!
      end

      it { expect(last_request.session[:game].player_name).to eq valid_name }
      it { expect(last_request.session[:game].difficulty[:level]).to eq difficulty_double.level[:level] }
      it { expect(response).to be_redirect }
      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to include I18n.t('game_page.hello', name: valid_name) }
    end

    context 'when invalid data must to be redirected to index with nil game session' do
      let(:invalid_name) { 'a' * (Codebreaker::User::VALID_NAME_SIZE.min - 1) }
      let(:invalid_level) { difficulty_double.level[:level].succ }
      let(:response) do
        post CodebreakerRack::URLS[:registration], player_name: invalid_name,
                                                   level: invalid_level
      end

      before do
        response
        follow_redirect!
      end

      it { expect(last_request.session[:game]).to eq nil }
      it { expect(response).to be_redirect }
      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to include I18n.t('menu_page.name_form.error') }
    end
  end

  describe 'when open NOT allowed pages with absent game phase must to be redirected to index' do
    CodebreakerRack::URLS.values.last(5).each do |url|
      before { get url }

      it { expect(last_response).to be_redirect }
      it do
        follow_redirect!
        expect(last_response).to be_ok
      end
      it do
        follow_redirect!
        expect(last_response.body).to include I18n.t('menu_page.name_form.label_name')
      end
    end
  end

  describe 'when open NOT allowed pages with active game phase must to be redirected to game page' do
    CodebreakerRack::URLS.values.first(6).each do |url|
      before do
        env 'rack.session', game: game
        get url
      end

      it { expect(last_response).to be_redirect }
      it do
        follow_redirect!
        expect(last_response).to be_ok
      end
      it do
        follow_redirect!
        expect(last_response.body).to include I18n.t('game_page.hello', name: valid_name)
      end
    end
  end

  describe 'when open show hint with active game phase must to be redirected to game page' do
    let(:response) { get CodebreakerRack::URLS[:show_hint] }
    let(:show_hint_button_with_disabled_css_class) do
      "<a class='btn btn-danger btn-lg float-right disabled' href='/show_hint' role='button'>"
    end

    before do
      env 'rack.session', game: game
      response
      follow_redirect!
    end

    it { expect(response).to be_redirect }
    it { expect(last_response).to be_ok }
    it { expect(last_request.session[:game].showed_hints).not_to eq nil }
    it { expect(last_response.body).to include I18n.t('game_page.hello', name: valid_name) }
    it { expect(last_response.body).to include last_request.session[:game].showed_hints.join }
    it { expect(last_response.body).not_to include show_hint_button_with_disabled_css_class }
  end

  describe "when use last hint 'show_hint' button must be disabled" do
    let(:show_hint_button_with_disabled_css_class) do
      "<a class='btn btn-danger btn-lg float-right disabled' href='/show_hint' role='button'>"
    end

    before { env 'rack.session', game: game }

    it do
      game.hints.times do
        get CodebreakerRack::URLS[:show_hint]
        follow_redirect!
      end
      expect(last_response.body).to include show_hint_button_with_disabled_css_class
    end
  end

  describe 'when post make guess with active game phase must to be redirected to game page' do
    before { env 'rack.session', game: game }

    context 'with valid guess result must NOT to be nil' do
      let(:response) { post CodebreakerRack::URLS[:make_guess], guess: wrong_guess }

      before do
        response
        game.instance_variable_set(:@breaker_numbers, valid_code)
        follow_redirect!
      end

      it { expect(response).to be_redirect }
      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to include I18n.t('game_page.hello', name: valid_name) }
      it { expect(last_request.session[:result]).not_to eq nil }
    end

    context 'with invalid guess result must to be nil' do
      let(:invalid_guess) { wrong_guess.slice(0, 2) }
      let(:response) { post CodebreakerRack::URLS[:make_guess], guess: invalid_guess }

      before do
        response
        follow_redirect!
      end

      it { expect(response).to be_redirect }
      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to include I18n.t('game_page.guess_form.error') }
      it { expect(last_request.session[:result]).to eq nil }
    end
  end

  describe 'when lose must to be redirected on lose page with deleting game session' do
    let(:response) { post CodebreakerRack::URLS[:make_guess], guess: wrong_guess }

    before do
      env 'rack.session', game: game
      game.instance_variable_set(:@breaker_numbers, valid_code)
      game.instance_variable_set(:@attempts, 1)
      response
      follow_redirect!
    end

    it { expect(response).to be_redirect }
    it { expect(last_response).to be_ok }
    it { expect(last_response.body).to include I18n.t('lose_page.lose_message', name: valid_name) }
    it { expect(last_request.session[:game]).to eq nil }
  end

  describe 'when win must to be redirected on win page with deleting game session and adding winner to db' do
    let(:right_guess) { '1666' }
    let(:path_to_test_db) { 'spec/fixtures/test_database.yml' }
    let(:response) { post CodebreakerRack::URLS[:make_guess], guess: right_guess }

    before do
      env 'rack.session', game: game
      game.instance_variable_set(:@breaker_numbers, valid_code)
      File.new(path_to_test_db, 'w+')
      stub_const('Codebreaker::Uploader::PATH', path_to_test_db)
      response
      follow_redirect!
    end

    after { File.delete(path_to_test_db) }

    it { expect(response).to be_redirect }
    it { expect(last_response).to be_ok }
    it { expect(last_response.body).to include I18n.t('win_page.congratulations', name: valid_name) }
    it { expect(last_request.session[:game]).to eq nil }
    it { expect(described_class.new(nil).load_db.empty?).to eq false }
  end
end
