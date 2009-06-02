module Pancake
  class Stack
    attr_reader :app
    
    include Rack::Router::Routable
    extend Middleware
    extend Hooks::OnInherit
    extend Hooks::InheritableInnerClasses
  
    def self.initialize_stack
      raise "Application root not set" if roots.empty?
      
      # Run any :init level bootloaders for this stack
      self::BootLoader.run!(:only => {:level => :init})
      
      roots.each do |root|  
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

    def initialize(app = nil, config = Configuration.new)
      self.class.initialize_stack unless self.class.initialized?
      
      app = app || self.class.new_app_instance
      @config = config
      
      mwares = self.class.middlewares
      
      @app = mwares.reverse.inject(app) do |a, m|
        m.middleware.new(a, m.opts, &m.block)
      end
      
      prepare do |r|
        self.class.stack_routes.each{|sr| sr.call(r)}
        r.map nil, :to => @app # Fallback route 
      end
      
    end
    
    # Construct a stack using the application, wrapped in the middlewares
    # :api: public
    def self.stack(opts = {}, &block)
      new(nil, opts, &block)
    end # stack

  end # Stack
end # Pancake