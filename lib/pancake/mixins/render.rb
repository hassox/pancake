require 'pancake/mixins/render/view_context'
module Pancake
  module Mixins
    module Render
      class TemplateNotFound < Pancake::Errors::NotFound; end

      RENDER_SETUP = lambda do |base|
        base.class_eval do
          extend  Pancake::Mixins::Render::ClassMethods
          include Pancake::Mixins::Render::InstanceMethods
          
          class ViewContext < Pancake::Mixins::Render::ViewContext; end
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
        
        def _view_cache
          @_view_cache ||= {}
        end

        def _find_template(name)
          renderer = _view_cache[name]
          return renderer if renderer
          
          renderer_path = unique_paths_for(:views, :invert => true).detect do |path|
            path.last =~ %r[(#{name})\.\w+$]
          end
          
          raise TemplateNotFound unless renderer_path
          _view_cache[name] = Tilt.new(renderer_path.join)
        end
      end # ClassMethods
      
      module InstanceMethods
        def render(*args)
          opts = Hash === args.last ? args.pop : {}
          name = args.shift
          
          return opts[:text] if opts[:text]
          
          # Get the template name to use
          template = _template_name_for(name, opts)
          
          # get the render template for that name
          renderer = self.class._find_template(template)
          
          # Render the results
          view_context = self.class::ViewContext.new(self)
          view_context_before_render(view_context)
          renderer.render(view_context, opts)
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
