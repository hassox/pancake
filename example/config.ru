require 'rubygems'

require ::File.join(::File.dirname(__FILE__), "../lib/pancake") # Normally just pancake

app = Pancake.start(:root => ::File.expand_path(::File.dirname(__FILE__)))

Pancake.mount do |r|
  r.map "/", :to => MyApp::Stack.stack
end

run app
