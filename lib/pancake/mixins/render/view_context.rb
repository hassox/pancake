require 'pancake/mixins/render/render.rb'
module Pancake
  module Mixins
    module Render
      class ViewContext
        # These are included as modules not for modularization, but because super can be called for the module versions
        include Capture
        include Renderer
        include ContentInheritance


        attr_reader :_view_context_for
        def initialize(renderer_for = nil)
          super
          @_view_context_for = renderer_for
        end

      end
    end
  end
end
