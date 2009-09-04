module Pancake
  # The pancake router is a customized version of the Usher router.
  # Usher is a fast tree based router that can generate routes, have
  # nested routers, and even generate from nested routers.
  # @see http://github.com/joshbuddy/usher
  # @since 0.1.2
  # @author Daniel Neighman
  class Router < Usher::Interface::RackInterface
    class RackApplicationExpected < ArgumentError; end
    attr_accessor :configuration
    # Mounts an application in the router as a sub application in the
    # url space.  This will route directly to the sub application and
    # skip any middlewares etc.
    def mount(mounted_app, path, options = {})
      raise RackApplicationExpected unless mounted_app.respond_to?(:call)
      exact_match = options.delete(:_exact)
      route = add(path, options)
      route.match_partially! unless exact_match
      route.to(mounted_app)
    end

    # Adds a route to the router.
    # @see Usher::Interface::RackInterface#add
    def add(path, opts = {})
      opts = cooerce_options_to_usher(opts)
      super(path, opts)
    end

    private
    # Canoodles the options into a format that usher is happy to
    # accept.  This is so that we can have a different interface from
    # the raw usher when we're first declaring the route.
    # @api private
    def cooerce_options_to_usher(opts)
      new_opts = Hash.new{|h,k| h[k] = {}}
      [:conditions, :default_values, :requirements].each do |attr|
        if _opts = opts.delete(attr)
          new_opts[attr].merge!(_opts)
        end
      end
      new_opts[:default_values] ||= {}
      new_opts[:default_values].merge!(opts) unless opts.empty?
      new_opts
    end

    # Overwrites the method in Rack::Interface::RackInterface to mash
    # the usher.params into the rack request.params
    # @api private
    def after_match(env, response)
      super
      r = Rack::Request.new(env)
      r.params.merge!(env['usher.params']) unless env['usher.params'].empty?
    end
  end
end
