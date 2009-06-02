module Pancake
  module Middleware
    def self.extended(base)
      base.class_eval do
        # Provides an inherited reader for middlewares
        class_inheritable_reader :middlewares
        @middlewares = []
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