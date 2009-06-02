class Pancake
  class Stack
    
    class Configuration < Pancake::Configuration::Base
    end
    
    # Provides access to the configuration block for the stack.
    # If a block is provided, it opens the specific configuration instances anonymous class
    # and allows you to edit it.
    # If no block is provided, it just returns the configuration object.
    # 
    # :api: public
    def self.configuration(label = self, &block)
      config = Pancake.configuration.configs[label] ||= self::Configuration.new
      config.class.class_eval(&block) if block
      config 
    end
    
    def configuration(label = self.class)
      self.class.configuration(label)
    end
    
  end # Stack
end # Pancake

Pancake::Stack.on_inherit do |base, parent|
  parent.roots.each{|r| base.roots << r}
end

####################
# Setup the default configuration for each stack
class Pancake::Stack::Configuration
  default :roots, [], "The various roots of this stack"
end