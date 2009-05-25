module Pancake
  class Stack
    extend Rack::Router::Routable
    extend Pancake::Middleware
    
    class << self      
      def initialize_stack
        raise "Application root not set" if roots.empty?
        # Here lies the application bootloader
        
        # Load any mounts this app has
        roots.each do |root|
          Dir["#{root}/mounts/*/pancake.init"].each{|f| load f if File.exists?(f)}
        
          # Load the App
          Dir["#{root}/app/**/*.rb"].each{|f| require f if File.exists?(f)}
        
          # Load the router
          require "#{root}/config/router" if File.exists?("#{root}/config/router")
        end
        @initialized = true
      end # initiailze stack
      
      def initialized?
        !!@initialized
      end
    end # self
  
  
    def this_stack
      self.class
    end

  end # Stack
end # Pancake