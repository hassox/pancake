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
          
          @action_opts  = actions[params["action"]]
          if params[:format]
            @content_type = params[:format].to_sym if @action_opts.formats.any?{|f| f.to_s == params[:format].to_s}
            @mime_type  = Pancake::MimeTypes.group(params[:format]).first
            ct = @mime_type.type_strings.first
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
