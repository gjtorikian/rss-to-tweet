begin
  require 'dotenv'
rescue LoadError
end

require 'sinatra/base'
require 'json'
# require 'openssl'
# require 'base64'
require 'nokogiri'
require 'open-uri'

require_relative './helpers'

class RssToTweet < Sinatra::Base
  set :root, File.dirname(__FILE__)
  Dotenv.load if !Sinatra::Base.production?

  helpers Helpers

  get '/' do
    'This server is running!'
  end

  post '/rss-to-tweet' do
    # trim trailing slashes
    request.path_info.sub!(%r{/$}, '')

    # ensure there's a payload
    request.body.rewind
    payload_body = request.body.read.to_s
    halt 400, 'Missing body payload!' if payload_body.nil? || payload_body.empty?

    # ensure signature is correct
    github_signature = request.env['HTTP_X_HUB_SIGNATURE']
    halt 401, 'Signatures didn\'t match!' unless signatures_match?(payload_body, github_signature)

    event = request.env['HTTP_X_GITHUB_EVENT']
    unless event == 'page_build'
      halt 202, 'Payload was not for a `page_build` event'
    end

    payload = JSON.parse(payload_body)

    status = payload['build']['status']

    unless status == 'built'
      halt 202, "Page build status was not `built`, it was `#{status}`, aborting"
    end

    doc = Nokogiri::HTML(open(ENV['RSS_PATH']))

    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = "YOUR_CONSUMER_KEY"
      config.consumer_secret     = "YOUR_CONSUMER_SECRET"
      config.access_token        = "YOUR_ACCESS_TOKEN"
      config.access_token_secret = "YOUR_ACCESS_SECRET"
    end

    client.update("I'm tweeting with @gem!")
  end
end
