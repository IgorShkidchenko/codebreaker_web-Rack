# frozen_string_literal: true

ruby '2.5.1'
source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'codebreaker_Shkidchenko', '~> 1.3.0'
gem 'i18n'
gem 'rack'

group :development do
  gem 'fasterer'
  gem 'html2haml'
  gem 'pry'
  gem 'rubocop', require: false
  gem 'rubocop-rspec'
end

group :test do
  gem 'rack-test'
  gem 'rspec'
  gem 'simplecov'
end
