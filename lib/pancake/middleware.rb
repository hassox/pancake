module Pancake
  module Middleware
    SomeMiddleware = Struct.new(:middleware, :opts, :block)
    
    # Use this to define middleware to include in the stack
    # 
    # :api: public
    def use(middleware, opts = {}, &block)
      _middlewares << SomeMiddleware.new(middleware, opts, &block)
    end # use
    
    # use this to prepend middleware to the stack
    # :api: public
    def prepend_use(middleware, opts = {}, &block)
      _middlewares.unshift SomeMiddleware.new(middleware, opts, &block)
    end
    
    private
    def _middlewares
      @middlewares ||= []
    end
    
  end # Middleware
end # Pancake