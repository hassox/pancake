module Pancake
  module Test
    module Helpers
      def clear_constants(*classes)
        classes.flatten.each do |klass|
          begin
            Object.class_eval do
              remove_const klass
            end
          rescue => e
          end
        end
      end # clear_constnat3

      def env_for(path = "/", opts = {})
        Rack::MockRequest.env_for(path, opts)
      end
    end # Helpers
  end
end
