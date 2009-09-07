module Pancake
  module Stacks
    class Short
      inheritable_inner_classes :Controller

      class Controller
        extend  Mixins::Publish
        include Mixins::Render

        # @api private
        def self.call(env)
          app = new(env)
          app.dispatch!
        end

        # @api public
        attr_reader :env, :request

        # @api public
        attr_accessor :status

        def initialize(env)
          @env, @request = env, Rack::Request.new(env)
          @status = 200

          request.params.merge!(request.env['rack_router.params']) if request.env['rack_router.params']
        end

        # Provides access to the request params
        # @api public
        def params
          request.params
        end

        # Dispatches to an action based on the params["action"] parameter
        def dispatch!
          params["action"] ||= params[:action]
          params["action"] ||= "index"

          # Check that the action is available
          raise Errors::NotFound, "No Action Found" unless allowed_action?(params["action"])

          Rack::Response.new(self.send(params["action"])).finish
        end

        private
        def allowed_action?(action)
          self.class.actions.include?(action.to_s)
        end

      end # Controller

    end # Short
  end # Stacks
end # Pancake