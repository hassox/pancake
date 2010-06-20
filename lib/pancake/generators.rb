require 'thor'
require 'thor/group'

Dir[File.join(File.dirname(__FILE__), "generators", "*.rb")].each do |f|
 require f unless f == 'base.rb'
end
