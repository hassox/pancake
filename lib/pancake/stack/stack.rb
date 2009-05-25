module Pancake
  class Stack
    extend Rack::Router::Routable
    extend Pancake::Middleware
  
    def self.initialize_stack
      raise "Application root not set" if roots.empty?
      
      # Run any :init level bootloaders for this stack
      # BootLoader.run!(:only => {:level => :init})
      
      roots.each do |root|
        # Load any mounts this app has
        Dir["#{root}/mounts/*/pancake.init"].each{|f| load f if File.exists?(f)}
      
        # Load the App
        Dir["#{root}/app/**/*.rb"].each{|f| require f if File.exists?(f)}
      
        # Load the router
        require "#{root}/config/router" if File.exists?("#{root}/config/router")
      end
      @initialized = true
    end # initiailze stack
      
    def self.initialized?
      !!@initialized
    end
    
    def self.roots
      configuration.roots
    end
  
    def this_stack
      self.class
    end

  end # Stack
end # Pancake