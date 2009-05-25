require 'rubygems'
require 'rack/router'

Dir[File.join(File.dirname(__FILE__), "pancake/**/*.rb")].each{|f| require f}

module Pancake
  # A simple rack application 
  OK_APP = lambda{|e| [200, {"Content-Type" => "text/plain"},"OK"]}
end # Panckae