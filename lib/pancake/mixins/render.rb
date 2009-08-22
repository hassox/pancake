module Pancake
  module Mixins
    module Render
      def self.included?(base)
        base.class_eval do
          def self.view_cache
            @view_cache ||= Tilt::Cache.new
          end
        end
      end
      
      def render(*args)
        opts = Hash === args.last ? args.pop : {}
        return opts[:text] if opts[:text]
      end
      
    end # Render
  end # Mixins
end # Pancake