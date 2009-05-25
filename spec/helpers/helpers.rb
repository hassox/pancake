module Pancake
  module Spec
    module Helpers
      def clear_constants(*classes)
        classes.flatten.each do |klass|
          begin            
            Object.class_eval do
              remove_const klass
            end
          rescue => e
            puts e.message
          end
        end
      end # clear_constnat3
    end # Helpers
  end # Spec
end # Pancake