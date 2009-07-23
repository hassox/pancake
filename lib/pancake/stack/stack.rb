module Pancake
  class Stack
    attr_accessor :app
    
    # extend Hooks::InheritableInnerClasses
    extend Hooks::OnInherit
    include Rack::Router::Routable
    extend Pancake::Middleware
  
    #Iterates the list of roots in the stack, and initializes the app found their
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

      self.class::BootLoader.run!({  
        :stack_class  => self.class,
        :stack        => self,
        :app          => app,
        :app_name     => app_name,
        :except       => {:level => :init}
      }.merge(opts))
    end
    
    # Construct a stack using the application, wrapped in the middlewares
    # :api: public
    def self.stackup(opts = {}, &block)
      new(nil, opts, &block)
    end # stack
    
    def klass
      self.class
    end

  end # Stack
end # Pancake
