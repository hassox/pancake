require 'thor'
require 'extlib'

Dir[File.join(File.dirname(__FILE__), "generators", "*.rb")].each{|f| require f}