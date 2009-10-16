module Pancake
  class Stack
    attr_accessor :app_name

    # extend Hooks::InheritableInnerClasses
    extend Hooks::OnInherit
    extend Pancake::Middleware
    extend Pancake::Paths

    # Push the default paths in for this stack
    push_paths(:config,       "config",               "config.rb")
    push_paths(:config,       "config/environments",  "#{Pancake.env}.rb")
    push_paths(:models,       "app/models",           "**/*.rb")
    push_paths(:controllers,  "app/controllers",      "**/*.rb")
    push_paths(:router,       "config",               "router.rb")

    #Iterates the list of roots in the stack, and initializes the app found their
    def self.initialize_stack
      raise "Application root not set" if roots.empty?

      # Run any :init level bootloaders for this stack
      self::BootLoader.run!(:stack_class => self, :only => {:level => :init})

      @initialized = true
    end # initiailze stack

    # Adds the file to the stack root.
    #
    # @param file - The file identifier
    # @example
    #   MyStack.add_root(__FILE__) # in a file in the root of the stack
    def self.add_root(*args)
      roots << Pancake.get_root(*args)
    end

    def self.initialized?
      !!@initialized
    end

    def initialize(app = nil, opts = {})
      @app_name = opts.delete(:app_name) || self.class
      self.class.initialize_stack unless self.class.initialized?
      Pancake.configuration.stacks[@app_name] = self

      # setup the configuration for this stack
      Pancake.configuration.configs[@app_name] = opts[:config] if opts[:config]
      self.configuration(@app_name)
      yield self.configuration(@app_name) if block_given?

      self.class::BootLoader.run!({
        :stack_class  => self.class,
        :stack        => self,
        :app          => app,
        :app_name     => @app_name,
        :except       => {:level => :init}
      }.merge(opts))
    end

    # Construct a stack using the application, wrapped in the middlewares
    # :api: public
    def self.stackup(opts = {}, &block)
      app = new(nil, opts, &block)
      Pancake.configuration.configs[app.app_name].router
    end # stackup
  end # Stack
end # Pancake
