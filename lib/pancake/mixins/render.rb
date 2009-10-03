require 'pancake/mixins/render/template'
require 'pancake/mixins/render/render'
require 'pancake/mixins/render/view_context'
module Pancake
  module Mixins
    module Render
      class TemplateNotFound < Pancake::Errors::NotFound; end

      RENDER_SETUP = lambda do |base|
        base.class_eval do
          extend  Pancake::Mixins::Render::ClassMethods
          include Pancake::Mixins::Render::InstanceMethods

          class self::ViewContext < Pancake::Mixins::Render::ViewContext; end
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

        def _find_template(name)
          renderer = _template_cache[name]
          return renderer if renderer

          renderer_path = unique_paths_for(:views, :invert => true).detect do |path|
            path.last =~ %r[^\/?(#{name})\.\w+$]
          end

          raise TemplateNotFound unless renderer_path
          _template_cache[name] = Template.new(name, renderer_path.join)
        end

        def _view_context_cache
          @_view_context_cache ||= {}
          @_view_context_cache
        end

        def _find_view_context_class_for(template)
          _view_context_cache[template] ||= begin
                                              Class.new(self::ViewContext)
                                            end
          _view_context_cache[template]
        end

        def _renderer_and_view_context_class_for(template)
          [_find_template(template), _find_view_context_class_for(template)]
        end


      end # ClassMethods

      module InstanceMethods
        def render(*args)
          opts = Hash === args.last ? args.pop : {}
          name = args.shift

          return opts[:text] if opts[:text]

          # Get the template name to use
          template = _template_name_for(name, opts)

          # Get the view context for the tempalte
          template, vc_class = self.class._renderer_and_view_context_class_for(template)

          view_context = vc_class.new(self)
          view_context_before_render(view_context)
          view_context.render(template, opts)
        end

        def template(name_or_template)
          case name_or_template
          when String, Symbol
            self.class._find_template(_template_name_for(name_or_template, {}))
          when Template
            name_or_template
          else
            nil
          end
        end

        # A place holder method for any implementor that wants
        # to configure the view context prior to rendering occuring
        # any time this method is overwritten, it should call super!
        #
        # @api overwritable
        def view_context_before_render(context)
        end

        private
        def _template_name_for(name, opts)
          opts[:format] ||= params[:format] || :html
          "#{name}.#{opts[:format]}"
        end
      end # InstanceMethods
    end # Render
  end # Mixins
end # Pancake
