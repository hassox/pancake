require 'rubygems'

require ::File.join(::File.dirname(__FILE__), "../lib/pancake") # Normally just pancake

app = Pancake.start(:root => Pancake.get_root(__FILE__)){ MyApp::Stack.stack }

run app