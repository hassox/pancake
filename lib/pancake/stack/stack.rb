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
    push_paths(:rake_tasks,   "tasks",                "**/*.rake")
    push_paths(:public,       "public",               "**/*")


    #Iterates the list of roots in the stack, and initializes the app found their
    def self.initialize_stack(opts = {})
      raise "Stack root not set" if roots.empty?
      master = opts.delete(:master)
      set_as_master! if master
      # Run any :init level bootloaders for this stack
      self::BootLoader.run!(:stack_class => self, :only => {:level => :init})
      # Pick up any new stacks added during the boot process.
      set_as_master! if master

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

      self.class::BootLoader.run!({
        :stack_class  => self.class,
        :stack        => self,
        :app          => app,
        :app_name     => @app_name,
        :except       => {:level => :init}
      }.merge(opts))
    end

    # Construct a stack using the application, wrapped in the middlewares
    # @api public
    def self.stackup(opts = {}, &block)
      app = new(nil, opts, &block)
      Pancake.configuration.configs[app.app_name].router
    end # stackup

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

    # Creates a bootloader hook(s) of the given name. That are inheritable
    # This will create hooks for use in a bootloader (but will not create the bootloader itself!)
    #
    # @example
    #   MyStack.create_bootloader_hook(:before_stuff, :after_stuff)
    #
    #   MyStack.before_stuff do
    #     # stuff to do before stuff
    #   end
    #
    #   MyStack.after_stuff do
    #     # stuff to do after stuff
    #   enc
    #
    #   MyStack.before_stuff.each{|blk| blk.call}
    #
    # @api public
    def self.create_bootloader_hook(*hooks)
      hooks.each do |hook|
        class_inheritable_reader "_#{hook}"
        instance_variable_set("@_#{hook}", [])

        class_eval <<-RUBY
          def self.#{hook}(&blk)
            _#{hook} << blk if blk
            _#{hook}
          end
        RUBY
      end
    end

    create_bootloader_hook :before_build_stack, :before_mount_applications, :after_initialize_application, :after_build_stack
  end # Stack
end # Pancake
