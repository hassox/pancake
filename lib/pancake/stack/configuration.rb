module Pancake
  class Stack
    
    module ConfigurationDefaults
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
      @configuration ||= ::Pancake.default_stack_configuration.new
      @configuration.class.class_eval(&block) if block
      @configuration        
    end
  end # Stack
  
  # Add extensions to the default stack configuration
  # This will affect all stack configurations
  # Provide it a block and it will open the default configurations 
  # anonymous class and let you edit it before returning the configuration class
  # 
  # :api: public
  def self.default_stack_configuration(&block)
    @DefaultStackConfiguration ||= ::Pancake::Configuration.make
    if block
      @DefaultStackConfiguration.class_eval(&block)
    end
    @DefaultStackConfiguration
  end # self.default_stack_configuration
end # Pancake

require File.join(File.dirname(__FILE__), "configuration", "roots")