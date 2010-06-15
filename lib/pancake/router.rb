module Pancake

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
    the_router.respond_to?(:base_url) ?
      the_router.base_url(opts) :
      "/"
  end

  # The pancake router uses a http_router router
  # @see http://github.com/joshbuddy/http_router
  # @since 0.1.2
  # @author Daniel Neighman
  class Router < HttpRouter
    attr_accessor :stack

    CONFIGURATION_KEY = "pancake.request.configuration".freeze
    ROUTE_KEY         = "pancake.request.matching_route".freeze
    LAYOUT_KEY        = "pancake.apply_layout".freeze

    class RackApplicationExpected < ArgumentError; end
    attr_accessor :configuration
    extlib_inheritable_accessor :mounted_applications
    self.mounted_applications = []

    class MountedApplication
      attr_accessor :mounted_app, :mount_path, :args, :stackup_with, :options,:mounted
      def initialize(mounted_app, mount_path, opts = {})
        @mounted_app, @mount_path = mounted_app, mount_path
        @stackup_with = opts.delete(:_stackup)      || :stackup
        @args         = opts.delete(:_args)         || []
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

      def mount!(route)
        app = nil
        if mounted_app.respond_to?(stackup_with)
          app = mounted_app.send(stackup_with, *args)
        else
          app = mounted_app
        end
        route.to(app)
        route.name(@name) if @name
        route.partial
        route
      end
    end

    def dup
      puts "Called DUP: #{caller.first}"
      clone
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

    def base_url(opts = {})
      url_mount.nil? ? "/" : url_mount.url(opts)
    end

    def call(env)
      apply_layout = env[LAYOUT_KEY]
      env[LAYOUT_KEY] = true if stack && stack.use_layout?

      orig_config = env[CONFIGURATION_KEY]
      orig_route  = env[ROUTE_KEY]
      env[CONFIGURATION_KEY] = configuration

      super(env)
    ensure
      env[CONFIGURATION_KEY] = orig_config
      env[ROUTE_KEY]         = orig_route
      env[LAYOUT_KEY]        = apply_layout
    end

    private
    def process_params(env, response)
      request = Rack::Request.new(env)
      request.env['rack.request.query_hash'] = request.params.dup
      super

      env['router.params'] = Hashie::Mash.new(env['router.params']) if env['router.params'] && ! env['router.params'].empty?

      request.env['rack.request.query_hash'].merge!(env['router.params']) unless env['router.params'].nil?
      # make the request params a hashie mash
      request.env['rack.request.query_hash'] = Hashie::Mash.new(request.params) unless request.params.kind_of?(Hashie::Mash)
    end
  end
end
