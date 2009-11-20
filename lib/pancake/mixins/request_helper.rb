module Pancake
  module Mixins
    # Some helpers for requests that come in handy for applications that
    # are part of stacks
    module RequestHelper
      VARS_KEY = 'pancake.request.vars'

      # A data area that allows you to carry data accross middlewares, controller / views etc.
      # Stores the data in session for the length of the request.
      #
      # @example
      #   vars[:user] = @user
      #   v[:user] == vault[:user]
      #   # This is now stored in the environment and is available later
      def vars
        env[VARS_KEY] ||= Hashie::Mash.new
        env[VARS_KEY]
      end
      alias_method :v, :vars

      # Get the configuration for this request.  This will be updated as the request makes its way through the stacks
      def configuration
        request.env[Pancake::Router::CONFIGURATION_KEY]
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
        configuration.router.url(name, opts)
      end

      # Generate the base url for the router that got you to this point.
      #
      # @example
      #   class MyApp
      #     router do |r|
      #       r.mount(SomeApp, "/some_app/:version")
      #     end
      #
      #   include Pancake::RequestHelper
      #   def call(env)
      #     @env = env
      #     base_url(:version => "1.0" #=> "/some_app/1.0
      #   end
      #  end
      #
      #  @see Usher
      #  @see Pancake::Router.base_url_for
      #  @see Pancake::Router#base_url
      #  @api public
      #  @author Daniel Neighman
      def base_url(opts={})
        configuration.router.base_url(opts)
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

      # Provides access to the logger object in rack.logger
      #
      #
      # @api public
      # @author Daniel Neighman
      def logger
        env[Pancake::Constants::ENV_LOGGER_KEY]
      end
    end # RequestHelper
  end # Mixins
end # Pancake
