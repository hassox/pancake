module Pancake
  # TODOS:
  # * Sketch out how action dispatch will work
  # * What helpers do we need for dealing with different formats?
  # * What are the different errors that might arise in dispatch? 404 etc.
  # * Get before and after hooks working. These wrap around all action calls
  #   by default, so the hooks in extlib aren’t useful. Additionally, the 
  #   the dispatch step gives us a point to hook in before and after the call.
  class Controller
    extend Mixins::Publish
    
    def self.call(env)
      new(env)      
    end
    
    def initialize(env)
     
    end
    
    # Returns the rack environment
    def request
      
    end
    
    # Returns a hash of parameters 
    def params

    end
    
    def render(opts = {})
      
    end
  end # Controller
end # Pancake
