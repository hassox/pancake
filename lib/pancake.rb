require 'rubygems'
require 'rack/router'

%w(
  master
  configuration
  bootloaders
  middleware 
  router
  stack/stack
  stack/configuration
  stack/app
  stack/inheritance
  stack/bootloader
).each do |file|
  path = File.join(File.dirname(__FILE__), "pancake")
  require File.join(path, file)
end


module Pancake
  # A simple rack application 
  OK_APP = lambda{|e| [200, {"Content-Type" => "text/plain"},"OK"]}
end # Panckae