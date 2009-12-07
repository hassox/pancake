module Pancake
  # Get the ability to mark this as a consuming route.
  class ::Usher::Route
    attr_accessor :consuming
  end

  # Generate a url for any pancake configuration that has a router
  #
  # @example
  #   Pancake.url(UserManamgent, :login) # => "/users/login"
  # @api public
  def self.url(app_name, name_or_opts, opts = {})
    config = Pancake.configuration.configs(app_name)
    the_router = if config && config.router
      config.router
    elsif app_name.respond_to?(:router)
      app_name.router
    else
      raise Pancake::Errors::UnknownRouter
    end
    the_router.url(name_or_opts, opts)
  end

  def self.base_url_for(app_name, opts={})
    config = Pancake.configuration.configs(app_name)
    the_router = if config && config.router
      config.router
    elsif app_name.respond_to?(:router)
      raise Pancake::Errors::UnknownRouter
    end
    the_router.base_url(opts)
  end

  # The pancake router is a customized version of the Usher router.
  # Usher is a fast tree based router that can generate routes, have
  # nested routers, and even generate from nested routers.
  # @see http://github.com/joshbuddy/usher
  # @since 0.1.2
  # @author Daniel Neighman
  class Router < Usher::Interface::Rack
    attr_writer :router

    CONFIGURATION_KEY = "pancake.request.configuration".freeze
    ROUTE_KEY         = "pancake.request.matching_route".freeze

    class RackApplicationExpected < ArgumentError; end
    attr_accessor :configuration
    class_inheritable_accessor :mounted_applications
    self.mounted_applications = []

    class MountedApplication
      attr_accessor :mounted_app, :mount_path, :args, :stackup_with, :options,:mounted
      def initialize(mounted_app, mount_path, opts = {})
        @mounted_app, @mount_path = mounted_app, mount_path
        @stackup_with = opts.delete(:_stackup)      || :stackup
        @args         = opts.delete(:_args)         || []
        @exact_match  = opts.delete(:_exact_match)  || false
        @options      = opts
      end

      def name(name = nil)
        unless name.nil?
          @name = name
        end
        @name
      end

      def mounted?
        !!@mounted
      end

      def exact_match?
        !!@exact_match
      end

      def mount!(route)
        app = nil
        route.consuming = true
        route.match_partially! unless exact_match?
        if mounted_app.respond_to?(stackup_with)
          app = mounted_app.send(stackup_with, *args)
        else
          app = mounted_app
        end
        route.to(app)
        route.name(@name) if @name
        route
      end
    end


    # Mounts an application in the router as a sub application in the
    # url space.  This will route directly to the sub application and
    # skip any middlewares etc defined on a stack
    def mount(mounted_app, path, options = {})
      mounted_app = MountedApplication.new(mounted_app, path, options)
      self.class.mounted_applications << mounted_app
      mounted_app
    end

    def mount_applications!
      # need to set them as mounted here before we actually to mount them.
      # if we just mounted them, the inheritance of the routes would mean that only the first would be mounted on this class
      # and the rest would be mounted on the child class
      apps = self.class.mounted_applications.select do |a|
        a.mounted? ? false : (a.mounted = true)
      end

      apps.each do |app|
        route = add(app.mount_path, app.options)
        app.mount!(route)
      end
    end

    # Adds a route to the router.
    # @see Usher::Interface::Rack#add
    def add(path, opts = {}, &block)
      opts = cooerce_options_to_usher(opts)
      route = super(path, opts)
      if block_given?
        route.to(block)
      end
      route
    end

    # Generate a url
    def url(name_or_path, options = {})
      if Hash === name_or_path
        name = nil
        options = name_or_path
      else
        name = name_or_path
      end
      u = generate(name, options)
      return u if u.nil?
      u.empty? ? "/" : u
    end

    def base_url(opts = {})
      router.generator.generate_base_url(opts)
    end

    def call(env)
      orig_config = env[CONFIGURATION_KEY]
      orig_route  = env[ROUTE_KEY]
      env[CONFIGURATION_KEY] = configuration
      super(env)
    ensure
      env[CONFIGURATION_KEY] = orig_config
      env[ROUTE_KEY]         = orig_route
    end

    private
    # Canoodles the options into a format that usher is happy to
    # accept.  This is so that we can have a different interface from
    # the raw usher when we're first declaring the route.
    # @api private
    def cooerce_options_to_usher(opts)
      defaults = opts.delete(:_defaults)
      opts[:default_values] ||= {}
      opts[:default_values].merge!(defaults) if defaults
      opts
    end

    # Overwrites the method in Rack::Interface::Rack to mash
    # the usher.params into the rack request.params
    # @api private
    def after_match(request, response)
      super
      consume_path!(request, response) if !response.partial_match? && response.path.route.consuming
      request.params.merge!(request.env['usher.params']) unless request.env['usher.params'].empty?
      request.env[ROUTE_KEY] = response.path.route
      request.env['rack.request.query_hash'] = Hashie::Mash.new(request.params) unless request.params.kind_of?(Hashie::Mash)
    end
  end
end
