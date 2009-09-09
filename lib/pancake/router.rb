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
  
  # The pancake router is a customized version of the Usher router.
  # Usher is a fast tree based router that can generate routes, have
  # nested routers, and even generate from nested routers.
  # @see http://github.com/joshbuddy/usher
  # @since 0.1.2
  # @author Daniel Neighman
  class Router < Usher::Interface::RackInterface
    CONFIGURATION_KEY = "pancake.request.configuration".freeze
    
    class RackApplicationExpected < ArgumentError; end
    attr_accessor :configuration
    
    # Mounts an application in the router as a sub application in the
    # url space.  This will route directly to the sub application and
    # skip any middlewares etc.
    def mount(mounted_app, path, options = {})
      raise RackApplicationExpected unless mounted_app.respond_to?(:call)
      exact_match = options.delete(:_exact)
      route = add(path, options)
      route.consuming = true
      route.match_partially! unless exact_match
      route.to(mounted_app)
    end

    # Adds a route to the router.
    # @see Usher::Interface::RackInterface#add
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
      generate(name, options)
    end

    def call(env)
      orig_config = env[CONFIGURATION_KEY]
      env[CONFIGURATION_KEY] = configuration
      super(env)
    ensure
      env[CONFIGURATION_KEY] = orig_config
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

    # Overwrites the method in Rack::Interface::RackInterface to mash
    # the usher.params into the rack request.params
    # @api private
    def after_match(env, response)
      super
      consume_path!(env, response) if !response.partial_match? && response.path.route.consuming
      r = Rack::Request.new(env)
      r.params.merge!(env['usher.params']) unless env['usher.params'].empty?
    end
  end
end
