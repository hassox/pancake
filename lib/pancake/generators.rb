require 'thor'
require 'extlib'

require File.join(File.dirname(__FILE__), "generators", "base.rb")

Dir[File.join(File.dirname(__FILE__), "generators", "*.rb")].each do |f|
 require f unless f == 'base.rb'
end
