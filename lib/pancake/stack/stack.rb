class Pancake
  class Stack
    attr_reader :app
    
    include Rack::Router::Routable
    extend Middleware
    extend Hooks::OnInherit
    extend Hooks::InheritableInnerClasses
  
    def self.initialize_stack
      raise "Application root not set" if roots.empty?
      
      # Run any :init level bootloaders for this stack
      self::BootLoader.run!(:stack_class => self, :only => {:level => :init})

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

    def initialize(app = nil, opts = {})
      app_name = opts.delete(:app_name) || self.class
      self.class.initialize_stack unless self.class.initialized?
      Pancake.configuration.stacks[app_name] = self
      
      # Get a new configuration
      Pancake.configuration.configs[app_name] = opts[:config] if opts[:config]
      configuration(app_name) # get the configuration if there's none been specified
      
      yield configuration if block_given?
      
      app = app || self.class.new_app_instance
            
      mwares = self.class.middlewares
      
      @app = Pancake::Middleware.build(app, mwares)
      
      prepare do |r|
        self.class.stack_routes.each{|sr| instance_exec(r, &sr)}
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