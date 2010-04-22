module Pancake
  module Mixins
    module Render
      class Template
        class UnamedTemplate < Pancake::Errors::NotFound; end
        class NotFound       < Pancake::Errors::NotFound; end

        attr_reader :name, :path, :renderer, :owner

        def initialize(name, owner, path)
          @name, @owner, @path = name, owner, path
          raise UnamedTemplate unless name
          raise NotFound unless File.exists?(path)
          @renderer = Tilt.new(path, :outvar => '@_erbout')
        end

        def render(context = Object.new, opts = {})
          @renderer.render(context, opts)
        end
      end #Template
    end #Render
  end #Mixins
end #Pancake
