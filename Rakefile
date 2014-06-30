require 'rubygems'
require 'bundler'
require 'rspec/core/rake_task'

Bundler::GemHelper.install_tasks

desc 'Default: run the specs.'
task :default do
  system("bundle exec rake -s appraisal spec:unit;")
end

namespace :spec do
  desc "Run unit specs"
  RSpec::Core::RakeTask.new('unit') do |t|
    t.pattern = 'spec/**/*_spec.rb}'
  end
end

desc "Run the unit and acceptance specs"
task :spec => ['spec:unit']
