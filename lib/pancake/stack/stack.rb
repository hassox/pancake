module Pancake
  class Stack
    extend Rack::Router::Routable
    extend Pancake::Middleware
    
    class << self
      
      def initialize_stack
        puts roots.inspect
        raise "Application root not set" if roots.empty?
        # Here lies the application bootloader
        
        # Load any mounts this app has
        Dir["#{root}/mounts/*/pancake.init"].each{|f| load f}
        
        # Load the App
        Dir["#{root}/app/**/*.rb"].each{|f| require f}
        
        # Load the router
        require "#{root}/config/router"
      end # initiailze stack
    end # self
      
    def this_stack
      self.class
    end

  end # Stack
end # Pancake