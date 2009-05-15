require 'rubygems'
require 'rack/router'

Dir[File.join(File.dirname(__FILE__), "pancake/**/*.rb")].each{|f| require f}