$TESTING=true
require 'rubygems'
require 'date'
require 'rack'
require 'rack/test'
require 'spec/rake/spectask'
require 'spec'
require 'haml'
require 'json'

ENV['RACK_ENV'] = "test"

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'pancake'

Dir[File.join(File.dirname(__FILE__), "helpers", "**/*.rb")].each{|f| require f}


Spec::Runner.configure do |config|
  config.include(Pancake::Test::Matchers)
  config.include(Pancake::Test::Helpers)
  config.include(Rack::Test::Methods)
end
