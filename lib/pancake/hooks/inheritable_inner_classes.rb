module Pancake
  module Hooks
    module InheritableInnerClasses
      def self.extended(base)
        base.class_eval do
          class_inheritable_reader :_inhertiable_inner_classes
          @_inhertiable_inner_classes = []
        end
      end # extended

      # Declare inner classes to be inherited when the outer class in inherited
      # The best way to show this is by example:
      #
      # @example
      #   class Foo
      #     inheritable_inner_class :Bar
      #
      #     class Bar
      #     end
      #   end
      #
      #   class Baz < Foo
      #     # When Foo is inherited, the following occurs
      #     class Bar < Foo::Bar; end
      #   end
      #
      # This provides a more organic inheritance where the child gets their own
      # version of the inner class which is actually inherited from the parents inner class.
      # The inheritance chain remains intact.
      #
      # @api public
      # @since 0.1.0
      # @author Daniel Neighman
      def inheritable_inner_classes(*classes)
        _inhertiable_inner_classes
        unless classes.empty?
          _inhertiable_inner_classes << classes
          _inhertiable_inner_classes.flatten!
        end
        _inhertiable_inner_classes
      end

      # The inherited hook that sets up inherited inner classes.  Remember if you overwrite this method, you should
      # call super!
      #
      # @api private
      # @since 0.1.0
      # @author Daniel Neighman
      def inherited(base)
        super
        class_defs = inheritable_inner_classes.map do |klass|
          "class #{klass} < superclass::#{klass}; end\n"
        end
        base.class_eval(class_defs.join)
      end

    end # InheritableInnerClasses
  end # Hooks
end # Pancake
