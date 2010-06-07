module Pancake
  class Stack
    attr_accessor :app_name
    class_inheritable_array :_after_stack_initialze, :_after_build_stack
    self._after_stack_initialze = []
    self._after_build_stack     = []

    # extend Hooks::InheritableInnerClasses
    extend Hooks::OnInherit
    extend Pancake::Middleware
    extend Pancake::Paths

    # Push the default paths in for this stack
    push_paths(:config,       "config",               "config.rb")
    push_paths(:config,       "config/environments",  "#{Pancake.env}.rb")
    push_paths(:rake_tasks,   "tasks",                "**/*.rake")
    push_paths(:public,       "public",               "**/*")
    push_paths(:mounts,       "mounts",               "*/pancake_init.rb")
    push_paths(:middlewares,  "config/middlewares",   "**/*.rb")


    #Iterates the list of roots in the stack, and initializes the app found their
    def self.initialize_stack(opts = {})
      raise "Stack root not set" if roots.empty?
      master = opts.delete(:master)
      set_as_master! if master

      paths_for(:config     ).each{ |f| require f.join }
      paths_for(:mounts     ).each{ |f| require f.join }
      paths_for(:middleware ).each{ |f| require f.join }

      router.mount_applications!

      set_as_master! if master
      @initialized = true
      # run the hook for after mounting
      after_stack_initialze.each{ |blk| blk.call(self) }
    end # initiailze stack


    def self.after_stack_initialze(&blk)
      _after_stack_initialze << blk if blk
      _after_stack_initialze
    end

    def self.after_build_stack(&blk)
      _after_build_stack << blk if blk
      _after_build_stack
    end

    # Adds the file to the stack root.
    #
    # @param file - The file identifier
    # @example
    #   MyStack.add_root(__FILE__) # in a file in the root of the stack
    def self.add_root(*args)
      roots << Pancake.get_root(*args)
    end
    add_root __FILE__, "defaults"


    def self.initialized?
      !!@initialized
    end

    def initialize(app = nil, opts = {})
      @app_name = opts.delete(:app_name) || self.class

      master = opts.delete(:master)
      self.class.initialize_stack(:master => master) unless self.class.initialized?
      self.class.set_as_master! if master
      Pancake.configuration.stacks[@app_name] = self

      # setup the configuration for this stack
      Pancake.configuration.configs[@app_name] = opts[:config] if opts[:config]
      self.configuration(@app_name)
      yield self.configuration(@app_name) if block_given?

      @app ||= self.class.new_endpoint_instance

      mwares = self.class.middlewares

      @stack = Pancake::Middleware.build(@app, mwares)
      app_config = Pancake.configuration.configs(@app_name)
      app_config.stack = self.class
      app_config.router.configuration = app_config
      router = Pancake.configuration.configs[@app_name].router
      router.default(@stack)
      self.class.after_build_stack{ |blk| blk.call(self, @app_name, opts) }
    end

    # Construct a stack using the application, wrapped in the middlewares
    # @api public
    def self.stackup(opts = {}, &block)
      app = new(nil, opts, &block)
      Pancake.configuration.configs[app.app_name].router
    end # stackup

    def call(env)
      Pancake.configuration.configs[@app_name].router.call(env)
    end


    # get a new instance of the application for this stack
    # Ovewrite this to provide custom application initialization
    # :api: overwritable
    def self.new_endpoint_instance
      MISSING_APP
    end

    # Loads the rake task for this stack, and all mounted stacks
    #
    # To have your rake task loaded include a "tasks" director in the stack root
    #
    # Tasks found in all stack roots are loaded in the order of the stack roots declearations
    #
    # @api public
    def self.load_rake_tasks!(opts={})
      stackup(opts) # load the application
      master = opts.delete(:master) # Don't get the other stacks to boot as master
      opts[:_rake_files_loaded] ||= []
      # For each mounted application, load the rake tasks
      self::Router.mounted_applications.each do |app|
        if app.mounted_app.respond_to?(:load_rake_tasks!)
          app.mounted_app.load_rake_tasks!(opts)
        end
      end
      paths_for(:rake_tasks).each do |f|
        path = File.join(*f)
        unless opts[:_rake_files_loaded].include?(path)
          load path
          opts[:_rake_files_loaded] << path
        end
      end
    end

    # Symlinks files in the public roots of this stack and all mounted stacks.
    # Provided a mounted application responds to the +symlink_public_files!+ method then it will be called.
    # symlinks public files from all roots of the stacks to Pancake.root/public
    #
    # @api public
    # @author Daniel Neighman
    def self.symlink_public_files!
      raise "Pancake root not set" unless Pancake.root

      public_root = File.join(Pancake.root, "public")
      mount_point = configuration.router.base_url

      unique_paths_for(:public).sort_by{|(r,p)| p}.each do |(r,p)|
        # don't try to symlink the symlinks
        origin_path = File.join(r, p)
        next if r == public_root || FileTest.directory?(origin_path)

        output_path = File.join(public_root, mount_point, p)

        unless File.exists?(File.dirname(output_path))
          FileUtils.mkdir_p(File.dirname(output_path))
        end
        # unless the dir exists... create it
        puts "Linking #{output_path}"
        FileUtils.ln_s(origin_path, output_path, :force => true)
      end

      router.mounted_applications.each do |s|
        if s.mounted_app.respond_to?(:symlink_public_files!)
          s.mounted_app.symlink_public_files!
        end
      end
    end

    # Specify a layout to use for this stack and all children stacks
    # Layouts are provided by Wrapt, and Pancake::Stacks::Short will use the layout when directed to by calling this method.  Simply call it to activate layouts with the default options, or provide it with options to direct wrapt.
    #
    # You can specify a layout to use by name, provide it options or provide a block that you can use to set the layout via the environment.
    #
    # @params name [String] (optional) The name of the layout to use
    # @params opts [Hash] Options for use with Wrapt
    #
    # @block The block is used to determine at runtime which layout to use.  It is yielded the environment where appropriate action can be taken.  It assumes that you will set the layout object directly
    #
    # @example
    #   # Direct the short stack to use a layout
    #   layout
    #
    #   # Set the layout to a non-default one
    #   layout "non_standard"
    #
    #   # Directly set the layout via the Wrapt::Layout object
    #   layout do |env|
    #     r = Rack::Request.new(env)
    #     l = env['layout']
    #     if r.params['foo'] == 'bar'
    #       l.template_name = "foo"
    #     end
    #   end
    #
    # @see Wrapt
    # @see Wrapt::Layout
    # @api public
    def self.apply_layout(name = nil, &blk)
      @use_layout = true
      @default_layout = name
    end

    def self.use_layout?
      if @use_layout
        @use_layout
      else
        @use_layout = superclass.respond_to?(:use_layout?) && superclass.use_layout?
      end
    end

    def self.default_layout
      if @default_layout
        @default_layout
      else
        @default_layout = superclass.respond_to?(:default_layout) && superclass.default_layout
      end
    end

    # Sets this as a master stack.  This means that the "master" directory will be added to all existing stack roots
    def self.set_as_master!
      Pancake.master_stack ||= self
      # Want to add master to the roots for this stack only
      roots.dup.each do |root|
        unless root =~ /master\/?$/
          roots << File.join(root, 'master')
        end
      end
    end

    def self.template(name,opts ={})
      raise Errors::NotImplemented, "Stack may not be used for templates until it implements a template method"
    end

    def self.base_template_name
      raise Errors::NotImplemented, "Stack may not be used for templates until it implements a base_template_name method"
    end
  end # Stack
end # Pancake

require 'pancake/stack/configuration'
require 'pancake/stack/router'
require 'pancake/defaults/middlewares'
require 'pancake/defaults/configuration'
