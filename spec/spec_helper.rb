$TESTING=true
require 'rubygems'
require 'date'
require 'rack'
require 'rack/test'
require 'spec/rake/spectask'
require 'spec'
require 'json'
require 'haml'

$:.push File.join(File.dirname(__FILE__), '..', 'lib')
require 'pancake'

Dir[File.join(File.dirname(__FILE__), "helpers", "**/*.rb")].each{|f| require f}


Spec::Runner.configure do |config|
  config.include(Pancake::Matchers)
  config.include(Pancake::Spec::Helpers)
  config.include(Rack::Test::Methods)
end
