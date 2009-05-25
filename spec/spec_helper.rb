$TESTING=true
require 'rubygems'
require 'rack'
require 'rack/test'

$:.push File.join(File.dirname(__FILE__), '..', 'lib')
require 'pancake'

def clear_constants(*classes)
  Object.class_eval do 
    begin
      classes.each{|k| remove_const(k)}
    rescue
    end
  end
end

