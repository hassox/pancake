class Pancake
  module Hooks 
    module InheritableInnerClasses
      def self.extended(base)
        base.class_eval do
          class_inheritable_reader :_inhertiable_inner_classes
          @_inhertiable_inner_classes = []
        end
      end # extended
  
      # Declare inner classes to be inherited when the outer class in inherited
      # :api: public
      def inheritable_inner_classes(*classes)
        @_inhertiable_inner_classes ||= []
        unless classes.empty?
          @_inhertiable_inner_classes += classes.flatten
        end        
        @_inhertiable_inner_classes
      end
      
      # An inherited hook for any extended classes to perform the inheriting of inner 
      # classes
      # :api: private
      def inherited(base)
        super
        class_defs = inheritable_inner_classes.map do |klass|
          "class #{klass} < #{self}::#{klass}; end\n"
        end
        base.class_eval(class_defs.join)
      end
      
    end # InheritableInnerClasses
  end # Hooks
end # Pancake