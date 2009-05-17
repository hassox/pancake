module Pancake
  module Middleware
    SomeMiddleware = Struct.new(:middleware, :opts, :block)
    
    # :api: private
    def self.extended(base)
      base.class_eval do 
        @middlewares = []
      end
    end
    
    # Use this to define middleware to include in the stack
    # 
    # :api: public
    def use(middleware, opts = {}, &block)
      @middlewares << SomeMiddleware.new(middleware, opts, &block)
    end # use
    
    # use this to prepend middleware to the stack
    # :api: public
    def use_prepend(middleware, opts = {}, &block)
      @middlewares.unshift SomeMiddleware.new(middleware, opts, &block)
    end
    
    # Construct a stack using the application, wrapped in the middlewares
    # :api: public
    def stack(opts = {}, &block)
      the_app = method(:initialize).arity == 1 ? new(opts, &block) : new(&block)
      middlewares = @middlewares
      
      Rack::Builder.new do
        middlewares.each do |m, opts|
          use m.middleware, m.opts
        end
        run the_app
      end
    end # stack
    
  end # Middleware
end # Pancake