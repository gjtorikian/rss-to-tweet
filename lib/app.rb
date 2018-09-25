# frozen_string_literal: true

begin
  require 'dotenv'
  require 'pry'
rescue LoadError
end

require 'sinatra/base'
require 'json'
require 'nokogiri'
require 'twitter'
require 'net/http'
require 'uri'
require 'octokit'

require_relative './helpers'

class RssToTweet < Sinatra::Base
  set :root, File.dirname(__FILE__)
  Dotenv.load if !Sinatra::Base.production?

  helpers Helpers

  TWEET_SIZE = 280

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

    Octokit.auto_paginate = true
    client = Octokit::Client.new(access_token: ENV['MACHINE_USER_TOKEN'])

    commit = payload['build']['commit']
    repo = payload['repository']['full_name']

    build_commit_info = client.commit(repo, commit)
    build_commit_info = JSON.parse(build_commit_info) if build_commit_info.is_a?(String)

    added_files = build_commit_info['files'].select do |f|
      f['status'] == 'added'
    end

    if added_files.empty?
      halt 202, 'Build did not add any files, aborting'
    end

    # TODO: ugh extract this hardcoded filename out, probably
    unless added_files.any? { |f| f['filename'] =~ %r{\Achanges/\d{4}-\d{2}-\d{1}} }
      halt 202, 'Build did not add any files for the RSS feed, aborting'
    end

    # give time to bust the Pages cache
    sleep 8

    if Sinatra::Base.test?
      doc = Nokogiri::HTML(File.read(ENV['RSS_PATH']))
    else
      doc = Nokogiri::HTML(Net::HTTP.get(URI.parse(ENV['RSS_PATH'])))
    end

    title = doc.xpath("//#{ENV['ENTRY_TITLE_PATH']}").text
    url = doc.xpath("//#{ENV['ENTRY_URL_PATH']}").text
    tweet = "#{title} #{url}"

    if tweet.size > TWEET_SIZE
      diff = TWEET_SIZE - url.size - 5
      title = "#{title[0..diff]}..."
      tweet = "#{title} #{url}"
    end

    client = ::Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['CONSUMER_KEY']
      config.consumer_secret     = ENV['CONSUMER_SECRET']
      config.access_token        = ENV['ACCESS_TOKEN']
      config.access_token_secret = ENV['ACCESS_TOKEN_SECRET']
    end

    client.update(tweet)

    status 204
  end
end
