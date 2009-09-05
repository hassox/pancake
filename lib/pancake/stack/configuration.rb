module Pancake
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
      yield self.class.configuration(label) if block_given?
      self.class.configuration(label)
    end

  end # Stack
end # Pancake

####################
# Setup the default configuration for each stack
class Pancake::Stack::Configuration
  default :router, lambda{ _router }, "The router for this stack"
  
  def _router
    @_router ||= begin
      unless stack.nil?
        r = stack.router.dup
        r.app = app
        r.configuration = self
        r
      end
    end
  end
end
