$TESTING=true
require 'rubygems'
require 'rack'
require 'rack/test'

$:.push File.join(File.dirname(__FILE__), '..', 'lib')
require 'pancake'

Dir[File.join(File.dirname(__FILE__), "helpers", "**/*.rb")].each{|f| require f}


Spec::Runner.configure do |config|  
  config.include(Pancake::Matchers)  
end

def clear_constants(*classes)
  Object.class_eval do 
    begin
      classes.each{|k| remove_const(k)}
    rescue
    end
  end
end

