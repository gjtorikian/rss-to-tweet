# frozen_string_literal: true

require File.expand_path '../test_helper.rb', __FILE__
require 'cgi'

class TweetTest < MiniTest::Test

  include Rack::Test::Methods

  def app
    RssToTweet
  end

  def setup
    RssToTweet.any_instance.stubs(:signatures_match?).returns(true)

    stub_request(:post, "#{::Twitter::REST::Request::BASE_URL}/oauth2/token")
    .with(body: {grant_type: 'client_credentials'})
    .to_return(body: load_fixture_text('bearer_token.json'),
               headers: {content_type: 'application/json; charset=utf-8'})


    @data = load_fixture_text('successful_build.json')
  end

  def stub_get_commit
    stub_request(:get, 'https://api.github.com/repos/gjtorikian/testing/commits/')
  end

  def stub_tweet(text)
    stub_request(:post, 'https://api.twitter.com/1.1/statuses/update.json')
    .with(body: {status: text})
    .to_return(body: load_fixture_text('status.json'), headers: {content_type: 'application/json; charset=utf-8'})
  end

  def assert_tweet_requested(text)
    assert_requested :post, 'https://api.twitter.com/1.1/statuses/update.json',
    body: "status=#{CGI.escape(text)}"
  end

  def refute_tweet_requested
    assert_not_requested :post, 'https://api.twitter.com/1.1/statuses/update.json'
  end

  def test_tweet_when_blog_filed_added
    stub_get_commit.to_return(status: 200, body: load_fixture_text('blog_file_added.json'), headers: {})

    with_env({ LAST_CHECKED_DATE: nil, RSS_PATH: File.join(fixtures_path, 'changes.atom') }) do
      text = 'Self-serve Onboarding for the GitHub Marketplace https://developer.github.com/changes/2018-04-06-self-serve-onboarding/'
      stub_tweet(text)
      post '/rss-to-tweet', @data, { 'HTTP_X_GITHUB_EVENT' => 'page_build', 'HTTP_X_HUB_SIGNATURE' => 'sha1=bf37c5205a39205d8cb4f70579be3fd79a1a74bb' }
      assert_equal last_response.status, 204
      assert_tweet_requested(text)
    end
  end

  def test_tweet_when_no_blog_filed_added
    stub_get_commit.to_return(status: 200, body: load_fixture_text('no_blog_file_added.json'), headers: {})

    with_env({ RSS_PATH: File.join(fixtures_path, 'changes.atom') }) do
      text = 'Self-serve Onboarding for the GitHub Marketplace https://developer.github.com/changes/2018-04-06-self-serve-onboarding/'
      post '/rss-to-tweet', @data, { 'HTTP_X_GITHUB_EVENT' => 'page_build', 'HTTP_X_HUB_SIGNATURE' => 'sha1=bf37c5205a39205d8cb4f70579be3fd79a1a74bb' }
      assert_equal last_response.status, 202
      refute_tweet_requested
    end
  end

  def test_tweet_when_blog_file_modified
    stub_get_commit.to_return(status: 200, body: load_fixture_text('blog_file_modified.json'), headers: {})

    with_env({ RSS_PATH: File.join(fixtures_path, 'changes.atom') }) do
      post '/rss-to-tweet', @data, { 'HTTP_X_GITHUB_EVENT' => 'page_build', 'HTTP_X_HUB_SIGNATURE' => 'sha1=bf37c5205a39205d8cb4f70579be3fd79a1a74bb' }
      assert_equal last_response.status, 202
      refute_tweet_requested
    end
  end

  def test_tweet_when_non_blog_file_added
    stub_get_commit.to_return(status: 200, body: load_fixture_text('other_file_added.json'), headers: {})

    with_env({ RSS_PATH: File.join(fixtures_path, 'changes.atom') }) do
      post '/rss-to-tweet', @data, { 'HTTP_X_GITHUB_EVENT' => 'page_build', 'HTTP_X_HUB_SIGNATURE' => 'sha1=bf37c5205a39205d8cb4f70579be3fd79a1a74bb' }
      assert_equal last_response.status, 202
      refute_tweet_requested
    end
  end

  def test_tweet_that_is_too_long
    stub_get_commit.to_return(status: 200, body: load_fixture_text('blog_file_added.json'), headers: {})

    with_env({ RSS_PATH: File.join(fixtures_path, 'too_long_changes.atom') }) do
      text = 'Lorem ipsum dolor amet trust fund adaptogen fixie tacos, flannel man braid shabby chic godard sartorial twee you probably haven\'t heard of them edison bulb. Coloring book listicle disrupt fashion axe photo ... https://developer.github.com/changes/2018-04-06-self-serve-onboarding/'
      stub_tweet(text)
      post '/rss-to-tweet', @data, { 'HTTP_X_GITHUB_EVENT' => 'page_build', 'HTTP_X_HUB_SIGNATURE' => 'sha1=bf37c5205a39205d8cb4f70579be3fd79a1a74bb' }
      assert_equal last_response.status, 204
      assert_tweet_requested(text)
    end
  end
end
