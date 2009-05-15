require 'rubygems'

# $:.unshift File.join(File.dirname(__FILE__), "../lib")
require ::File.join(::File.dirname(__FILE__), "../lib/pancake")

app = Pancake.start(:root => ::File.expand_path(::File.dirname(__FILE__)))

Pancake::Router.prepare do |r|
  r.map "/", :to => MyApp.stack
end

Rack::Handler::Thin.run app, :Port => 22000


