$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH << File.join(File.dirname(__FILE__))

require 'rubygems'
require 'rspec'

# require "simplecov"

require 'csv_model'
require 'ostruct'

Dir["spec/support/**/*.rb"].each { |f| require File.expand_path(f) }

RSpec.configure do |config|
  config.order = "random"

  config.before(:suite) do
    srand(config.seed)
  end
end
