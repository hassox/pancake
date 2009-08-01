module Pancake
  # The route builder for pancake stacks.
  # Mixin to this class to extend the router with new methods
  class RouteBuilder < Rack::Router::Builder::Simple
    
    # Mounts an application inside the router
    # 
    # @param [String] path        The relative url path prefix to mount this application at in the url namespace
    # @param [Object] app         The rack complient application to mount at <path>
    # @param [Hash]   with        The options of parameters to set when the route is matched
    # @param [Hash]   conditions  Conditions that must be met for this route to match
    #
    # @see http://github.com/carllerche/rack-router/tree/master
    # @api public
    # @since 0.1.0
    # @author Daniel Neighman
    def mount(path, app, with = {}, conditions = {})
      map path, :to => app, :with => with, :conditions => conditions
    end
    
    # Mount a rails application inside a pancake router.
    # Be sure you know what you're doing when you use this
    #
    # @api public
    # @since 0.1.0
    # @author Daniel Neighman
    def mount_rails(path, with = {}, conditions = {})
      if Rails.version =~ /^2\.3/
        ::ActionController::Base.relative_url_root = path
        app = ::ActionController::Dispatcher.new($stdout)
      else
        raise "Rails version unsupported"
      end
      map path, :to => app, :with => with, :conditions => conditions
    end
    
  end # RouteBuilder
end # Pancake 