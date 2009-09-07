module Pancake
  module Mixins
    # Some helpers for requests that come in handy for applications that
    # are part of stacks
    module RequestHelper

      # A setter for the rack environment
      # @api public
      def env=(env)
        @env = env
      end

      # An accessor for the rack environment variable
      # @api public
      def env
        @env
      end
      
   
      # Generate a url for the current stacks router.
      #
      # @example
      #   class MyApp
      #     router do |r|
      #       r.add("/foo").name(:foo)
      #     end
      #
      #     include Pancake::RequestHelper
      #     # snip
      #     def call(env)
      #       @env = env
      #       url(:foo) # => "/foo"
      #     end
      #   end
      #
      # @see Usher
      # @see Pancake::Router
      # @api public
      # @author Daniel Neighman
      def url(name, opts = {})
        konfig = request.env[Pancake::Router::CONFIGURATION_KEY]
        konfig.router.generate(name, opts)
      end
      
      # Generate a url for any registered configuration with a router
      #
      # @example
      #   # an application declared with MyApp.stackup(:app_name =>
      #:some_app)
      #   url_for(:some_app, :my_named_route)
      #
      #   # An application with no name specified
      #   url_for(MyApp, :my_named_route)
      #
      # @see Usher
      # @see Pancake::Router
      # @api public
      # @author Daniel Neighman
      def url_for(app_name, name_or_opts, opts = {})
        if konfig = Pancake.configuration.configs[app_name]
          konfig.router.generate(name_or_opts, opts)
        else
          raise Pancake::Errors::UnknownConfiguration
        end
      end
   
      # A handy request method that gets hold of the current request
      # object for the current rack request.
      # Any including class _must_ provide an +env+ method that exposes
      # the rack request environment
      #
      # @see Rack::Request
      # @api public
      # @author Daniel Neighman
      def request
        @request ||= Rack::Request.new(env)
      end
      
    end # RequestHelper
  end # Mixins
end # Pancake
