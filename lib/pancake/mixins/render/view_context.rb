module Pancake
  module Mixins
    module Render
      class ViewContext
        attr_reader :view_context_for
        def initialize(renderer_for = nil)
          @view_context_for = renderer_for
        end

        # Defers to the object that is rendering this context
        # Allows you to call render from within a template
        def render(*args)
          @view_context_for.render(*args)
        end
      end
    end
  end
end
