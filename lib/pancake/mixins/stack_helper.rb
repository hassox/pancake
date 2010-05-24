module Pancake
  module Mixins
    module StackHelper
      def self.included(base)
        base.extlib_inheritable_accessor :_stack_class
        base.extend ClassMethods
        base.class_eval do
          include ::Pancake::Mixins::StackHelper::InstanceMethods
        end
        base.stack_class
      end

      module ClassMethods
        def stack_class
          return @_stack_class if @_stack_class
          klass = nil
          if name =~ /^\#<Class/
            raise "Could not determine the stack.  Make sure you declare global classes with a preceeding ::"
          end
          ns = name.split("::")
          until ns.empty? || klass
            r = ns.join("::").constantize
            if r.ancestors.include?(::Pancake::Stack)
              klass = r
            else
              ns.pop
            end
          end
          if klass.nil?
            raise "#{name} is not from a stack" unless _stack_class
          else
            self._stack_class = r
          end
          _stack_class
        end
      end

      module InstanceMethods
        def stack_class
          self.class.stack_class
        end
      end

    end # StackHelper
  end # Mixins
end # Pancake
