module Pancake
  class Stack
    
    class Configuration < Pancake::Configuration::Base
      module ClassMethods; end
      module InstanceMethods; end
    end
    
    # Provides access to the configuration block for the stack.
    # If a block is provided, it opens the specific configuration instances anonymous class
    # and allows you to edit it.
    # If no block is provided, it just returns the configuration object.
    # 
    # :api: public
    def self.configuration(&block)
      @configuration ||= self::Configuration.new
      @configuration.class.class_eval(&block) if block
      @configuration        
    end
  end # Stack
end # Pancake

# When a stack is inherited, a new configuration is built that inherits from the parent configuration
Pancake::Stack.on_inherit do |base, parent|
  base.class_eval do
    class Configuration < parent::Configuration; end
  end
end

require File.join(File.dirname(__FILE__), "configuration", "roots")