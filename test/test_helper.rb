# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'rack/test'
require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/focus'
require 'webmock/minitest'

# Load the sinatra application
require_relative '../lib/app'

File.rename('.env.example', '.env') if ENV['CI']

def with_env(hash)
  current_values = {}

  hash.each_pair do |key, val|
    current_values[key.to_s] = ENV[key.to_s]
    ENV[key.to_s] = val
  end

  yield

  ensure
    current_values.each_pair do |key, val|
      ENV[key] = val
    end
end

def fixtures_path
  File.join('test', 'fixtures')
end

def load_fixture_text(*file)
  File.open(File.join(fixtures_path, file), &:read)
end
