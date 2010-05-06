module Pancake
  module Stacks
    class Short
      inheritable_inner_classes :Controller
      class Controller
        extend  Mixins::Publish
        include Mixins::Render
        include Mixins::RequestHelper
        include Mixins::ResponseHelper
        include Mixins::StackHelper

        class self::ViewContext
          include Mixins::RequestHelper
          include AnyView

          # No way to get the env into the view context... this is not good :(
          def env
            _view_context_for.env
          end

          def self.template(name_or_template, opts = {})
            opts[:format] ||= content_type
            super
          end

          def template(name_or_template, opts={})
            opts[:format] ||= content_type
            super
          end

          def _template_name_for(name, opts = {})
            opts[:format] ||= :html
            "#{name}.#{opts[:format]}"
          end
        end

        class_inheritable_accessor :_handle_exception

        push_paths(:views, ["app/views", "views"], "**/*")

        DEFAULT_EXCEPTION_HANDLER = lambda do |error|
          use_layout = env[Router::LAYOUT_KEY]
          if use_layout
            layout = env['layout']
            layout.content = render :error, :error => error
            layout
          else
            render :error, :error => error
          end
        end unless defined?(DEFAULT_EXCEPTION_HANDLER)

        # @api private
        def self.call(env)
          app = new(env)
          app.dispatch!
        end

        def layout
          env['layout']
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
          params[:format]  ||= params["format"]

          if logger
            logger.info "Request: #{request.path}"
            logger.info "Params: #{params.inspect}"
          end

          # Check that the action is available
          raise Errors::NotFound, "No Action Found" unless allowed_action?(params["action"])

          @action_opts  = actions[params["action"]]

          negotiate_content_type!(@action_opts.formats, params)

          # Setup the layout
          use_layout = env[Router::LAYOUT_KEY]
          layout = env['layout']

          # Set the layout defaults before the action is rendered
          if use_layout && stack_class.default_layout
            layout.template_name = stack_class.default_layout
          end
          layout.format = params['format'] if use_layout

          logger.info "Dispatching to #{params["action"].inspect}" if logger

          result = catch(:halt){ self.send(params['action']) }

          case result
          when Array
            result
          when Rack::Response
            result.finish
          when String
            out = if use_layout
              layout.content = result
              layout
            else
              result
            end
            Rack::Response.new(out, status, headers).finish
          else
            Rack::Response.new((result || ""), status, headers).finish
          end

        rescue Errors::HttpError => e
          if logger && log_http_error?(e)
            logger.error "Exception: #{e.message}"
            logger.error e.backtrace.join("\n")
          end
          handle_request_exception(e)
        rescue Exception => e
          if Pancake.handle_errors?
            server_error = Errors::Server.new(e.message)
            server_error.exceptions << e
            server_error.set_backtrace e.backtrace
          else
            server_error = e
          end
          handle_request_exception(server_error)
        end

        def log_http_error?(error)
          true
        end

        def self.handle_exception(&block)
          if block_given?
            self._handle_exception = block
          else
            self._handle_exception || DEFAULT_EXCEPTION_HANDLER
          end
        end

        def handle_request_exception(error)
          raise(error.class, error.message, error.backtrace) unless Pancake.handle_errors?
          self.status = error.code
          result = instance_exec error, &self.class.handle_exception
          Rack::Response.new(result, status, headers).finish
        end

        private
        def allowed_action?(action)
          self.class.actions.include?(action.to_s)
        end

        public
        def self.roots
          stack_class.roots
        end

        def self._template_name_for(name, opts)
          opts[:format] ||= :html
          "#{name}.#{opts[:format]}"
        end

        def _tempate_name_for(name, opts = {})
          opts[:format] ||= content_type
          self.class._template_name_for(name, opts)
        end
      end # Controller

    end # Short
  end # Stacks
end # Pancake
