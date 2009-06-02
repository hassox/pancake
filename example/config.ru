require 'rubygems'

require ::File.join(::File.dirname(__FILE__), "../lib/pancake") # Normally just pancake

# get the application to run.  The applicadtion in the Pancake.start block
# is the master application.  It will have all requests directed to it through the 
# pancake middleware
# This should be a very minimal file, but should be used when any stand alone code needs to be included
app = Pancake.start(:root => Pancake.get_root(__FILE__)){ MyApp::Stack.stack }

run app