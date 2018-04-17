# frozen_string_literal: true

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.warning = false
end

require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop)

namespace :deploy do
  desc 'Deploy the app'
  task :production do
    branch = ENV['BRANCH'] || 'master'
    app = 'github-rss-to-tweet'
    remote = "git@heroku.com:#{app}.git"

    system "heroku maintenance:on --app #{app}"
    system "git push --force #{remote} #{branch}:master"
    system "heroku run rake db:migrate --app #{app}"
    system "heroku maintenance:off --app #{app}"
  end
end
