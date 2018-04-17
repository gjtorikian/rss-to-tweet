# frozen_string_literal: true

require './lib/app'

map('/') { run RssToTweet }
