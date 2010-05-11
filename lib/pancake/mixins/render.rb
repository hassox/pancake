require 'pancake/mixins/render/template'
require 'pancake/mixins/render/view_context'
module Pancake
  module Mixins
    module Render
      class TemplateNotFound < Pancake::Errors::NotFound; end

      RENDER_SETUP = lambda do |base|
        base.class_eval do
          extend  Pancake::Mixins::Render::ClassMethods
          include Pancake::Mixins::Render::InstanceMethods

          class base::ViewContext < Pancake::Mixins::Render::ViewContext; end

          inheritable_inner_classes :ViewContext

          unless ancestors.include?(Pancake::Paths)
            extend Pancake::Paths
          end
        end
      end

      def self.included(base)
        RENDER_SETUP.call(base)
      end

      module ClassMethods

        def _template_cache
          @_template_cache ||= {}
        end

        # Allows you to set path label for the templates for this class
        #
        # @example
        #   MyClass.push_paths(:my_templates, "somewhere", "**/*")
        #
        #   MyClass._template_path_name #=> :my_templates
        # @api public
        def _template_path_name(opts = {})
          opts[:template_path_name] || :views
        end

        def _find_template(name, opts = {})
          template(name, opts)
        end

        def _view_context_cache
          @_view_context_cache ||= {}
          @_view_context_cache
        end

        def _find_view_context_class_for(template)
          _view_context_cache[template] ||= begin
                                              self::ViewContext
                                            end
          _view_context_cache[template]
        end

        def _renderer_and_view_context_class_for(tplate)
          [template(tplate), _find_view_context_class_for(tplate)]
        end

        def _template_name_for(name, opts)
          "#{name}"
        end

        def template(name, opts = {})
          case name
          when Template
            name
          when String, Symbol

            template_names = case __template = _template_name_for(name, opts)
            when String, Symbol
              [__template]
            when Array
              __template
            when Proc
              [__template.call(opts)].flatten
            else
              nil
            end

            renderer = _template_cache[template_names]
            return renderer if renderer

            unique_paths = unique_paths_for(_template_path_name(opts), :invert => true)

            renderer_path = nil
            template_name = nil

            template_names.detect do |tn|
              unique_paths.detect do |path|
                if path.last =~ %r[^\/?(#{tn})\.\w+$]
                  template_name = tn
                  renderer_path = path.join
                end
              end
            end

            raise TemplateNotFound unless renderer_path
            _template_cache[template_names] = Template.new(template_name, self, renderer_path)
          else
            nil
          end
        end

        def base_template_name
          :base
        end

      end # ClassMethods

      module InstanceMethods
        def render(*args)
          opts          = Hash === args.last ? args.pop : {}
          name          = args.shift
          template      = self.class.template(name, opts)
          return opts[:text] if opts[:text]

          # Get the view context for the tempalte
          template, vc_class = self.class._renderer_and_view_context_class_for(template)

          yield v if block_given?

          view_context = vc_class.new(self)
          view_context_before_render(view_context)
          view_context.render(template, opts)
        end

        def partial(*args)
          opts  = Hash === args.last ? args.pop : {}
          opts  = opts.dup
          name  = args.shift
          with  = opts.delete(:with)
          as    = opts.delete(:as)

          partial_name = _partial_template_name_for(name, opts)
          # Get the view context for the tempalte
          template, vc_class = self.class._renderer_and_view_context_class_for(partial_name)

          view_context = vc_class.new(self)
          view_context_before_render(view_context)

          out = ""

          if with.kind_of?(Array)
            with.each do |item|
              as.nil? ? (opts[name] = item) : (opts[as] = item)
              out << view_context.render(template, opts)
            end
          else
            as.nil? ? (opts[name] = with) : (opts[as] = with)
            out << view_context.render(template, opts)
          end
          out
        end

        def template(name_or_template, opts = {})
          self.class.template(name_or_template, opts)
        end

        # A place holder method for any implementor that wants
        # to configure the view context prior to rendering occuring
        # any time this method is overwritten, it should call super!
        #
        # @api overwritable
        def view_context_before_render(context)
        end

        private
        # @api_overwritable
        def _template_name_for(name, opts = {})
          self.class._template_name_for(name, opts)
        end

        def _partial_template_name_for(name, opts)
          "_#{_template_name_for(name, opts)}"
        end
      end # InstanceMethods
    end # Render
  end # Mixins
end # Pancake
