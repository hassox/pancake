class Pancake
  module Spec
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
    end # Helpers
  end # Spec
end # Pancake