module Pancake
  # A simple rack application
  OK_APP      = lambda{|env| Rack::Response.new("OK",         200,  {"Content-Type" => "text/plain"}).finish}
  MISSING_APP = lambda{|env| Rack::Response.new("NOT FOUND",  404,  {"Content-Type" => "text/plain"}).finish}

  extend Middleware

  class << self
    attr_accessor :root
    attr_accessor :_before_build

    def before_build(&blk)
      unless _before_build
        self._before_build = []
      end
      _before_build << blk if blk
      _before_build
    end

    # Start Pancake.  This provides a full pancake stack to use inside a rack application
    #
    # @param        [Hash]    opts
    # @option opts  [String]  :root   The root of the pancake stack
    #
    # @example Starting a pancake stack
    #   Pancake.start(:root => "/path/to/root"){ MyApp # App to use}
    #
    # @api public
    # @author Daniel Neighman
    def start(opts = {}, &block)
      self.root = opts[:root] || Dir.pwd

      # Build Pancake
      the_app = instance_eval(&block)
      before_build.each{|blk| blk.call}

      Pancake::Middleware.build(the_app, middlewares)
    end

    # Provides the environment for the currently running pancake
    #
    # @return [String] The currently running environment
    # @api public
    # @author Daniel Neighman
    def env
      ENV['RACK_ENV'] ||= "development"
    end

    # A helper method to get the expanded directory name of a __FILE__
    #
    # @return [String] an expanded version of file
    # @api public
    # @author Daniel Neighman
    def get_root(file, *args)
      File.expand_path(File.join(File.dirname(file), *args))
    end


    def handle_errors!(*args)
      @handle_errors = begin
        if args.size > 1
          args.flatten
        else
          args.first
        end
      end
    end

    def handle_errors?
      if @handle_errors.nil?
        !(Pancake.env == "development")
      else
        case @handle_errors
        when Array
          @handle_errors.include?(Pancake.env)
        when TrueClass, FalseClass
          @handle_errors
        when String
          Pancake.env == @handle_errors
        end
      end
    end

    def default_error_handling!
      @handle_errors = nil
    end

    def logger
      @logger ||= Pancake::Logger.new
    end

    def logger=(logr)
      @logger = logr
    end

    # The stack to use as the master stack.  Can be nil!
    # The master stack is assumed to be the stack that is the controlling stack for the group of pancake stacks
    # @api public
    def master_stack
      @master_stack
    end

    # set the master stack.  This also sets the master_templates as this stack if that hasn't yet been set.
    # @see Pancake.master_templates
    # @api public
    def master_stack=(stack)
      self.master_templates ||= stack
      @master_stack = stack
    end

    # Used as the definitive source of shared templates for the whole pancake graph.
    # Allows different stacks to share the same templates
    # @see Pancake.master_templates=
    # @api public
    def master_templates
      @master_templates
    end

    # Set the master templates to control the default templates for the stack
    # @see Pancake.master_templates
    # @api public
    def master_templates=(stack)
      @master_templates = stack
    end

    # provides access to the default base template via the Pancake.master_templates object
    # @see Pancake.master_templates
    # @api public
    def default_base_template(opts = {})
      raise "Master Templates not set" unless master_templates
      master_templates.template(master_templates.base_template_name)
    end
  end # self
end # Pancake
