module Pancake
  module Stacks
    class Short
      inheritable_inner_classes :Controller

      class Controller
        extend  Mixins::Publish
        include Mixins::Render
        include Mixins::RequestHelper

        # @api private
        def self.call(env)
          app = new(env)
          app.dispatch!
        end

        # @api public
        attr_accessor :status

        def initialize(env)
          @env, @request = env, Rack::Request.new(env)
          @status = 200
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
          params[:format]  ||= params["format"]

          # Check that the action is available
          raise Errors::NotFound, "No Action Found" unless allowed_action?(params["action"])
          
          @action_opts  = actions[params["action"]]
          if params[:format]
            @content_type, ct, @mime_type = Pancake::MimeTypes.negotiate_by_extension(params[:format].to_s, @action_opts.formats)
          else
            @content_type, ct, @mime_type = Pancake::MimeTypes.negotiate_accept_type(env["HTTP_ACCEPT"], @action_opts.formats)
          end
          
          raise Errors::NotAcceptable unless @content_type

          # set the response header
          headers["Content-Type"] = ct
          
          Rack::Response.new(self.send(params["action"]), status, headers).finish
        end

        def content_type
          @content_type
        end

        private
        def allowed_action?(action)
          self.class.actions.include?(action.to_s)
        end

      end # Controller

    end # Short
  end # Stacks
end # Pancake
