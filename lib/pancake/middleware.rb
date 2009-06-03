module Pancake
  module Middleware
    def self.extended(base)
      base.class_eval do
        # Provides an inherited reader for middlewares
        if base.is_a?(Class)
          class_inheritable_reader :middlewares
          @middlewares = []
        else
          def self.middlewares
            @middlewares ||= []
          end
        end
      end
    end
    
    def self.build(app, mwares)
      mwares.reverse.inject(app) do |a, m|
        m.middleware.new(a, m.opts, &m.block)
      end
    end
    
    SomeMiddleware = Struct.new(:middleware, :opts, :block)
    
    # Use this to define middleware to include in the stack
    # 
    # :api: public
    def use(middleware, opts = {}, &block)
      middlewares << SomeMiddleware.new(middleware, opts, &block)
    end # use
    
    # use this to prepend middleware to the stack
    # :api: public
    def prepend_use(middleware, opts = {}, &block)
      middlewares.unshift SomeMiddleware.new(middleware, opts, &block)
    end
  end # Middleware
end # Pancake