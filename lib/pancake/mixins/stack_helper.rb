module Pancake
  module Mixins
    module StackHelper
      def self.included(base)
        base.class_inheritable_accessor :_stack_class
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
          ns = name.split("::")
          until ns.empty? || klass
            r = Object.full_const_get(ns.join("::"))
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
