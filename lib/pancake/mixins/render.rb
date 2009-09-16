module Pancake
  module Mixins
    module Render
      class TemplateNotFound < Pancake::Errors::NotFound; end
      
      def self.included(base)
        base.class_eval do
          extend  Pancake::Mixins::Render::ClassMethods
          include Pancake::Mixins::Render::InstanceMethods
          
          unless ancestors.include?(Pancake::Paths)
            extend Pancake::Paths
          end
        end
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
          renderer.render(self, opts)
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
