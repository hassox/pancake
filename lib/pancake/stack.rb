module Pancake
  class Stack
    extend  Rack::Router::Routable
    
    class << self
      attr_accessor :root
      
      def initialize_stack
        raise "Application root not set" if root.nil?
        # Here lies the application bootloader
        
        # Load any mounts this app has
        Dir["#{root}/mounts/*/pancake.init"].each{|f| load f}
        
        # Load the App
        Dir["#{root}/app/**/*.rb"].each{|f| require f}
        
        # Load the router
        require "#{root}/config/router"
      end # initiailze stack
      
      def stack
        the_app = self
        Rack::Builder.new do
          run the_app
        end
      end # setup
    end # self
      
    def this_stack
      self.class
    end

  end # Stack
end # Pancake