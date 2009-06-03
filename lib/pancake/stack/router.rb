module Pancake 
  class Stack
    # An internal accessor for building the routes of a stack
    class_inheritable_reader :stack_routes
    @stack_routes = []
    include ::Rack::Router::Routable
    
    # Make the prepare call private so only the stack can actually prepare the routes
    private :prepare
    
    def self.add_routes(&block)
      stack_routes << block
    end
    
    def self.prepend_routes(&block)
      stack_routes.unshift block
    end
    
  end
end
    