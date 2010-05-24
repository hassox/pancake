module Pancake
  module Hooks
    module OnInherit
      def self.extended(base)
        base.class_eval do
          extlib_inheritable_reader :_on_inherit
          @_on_inherit = []
        end
      end

      # Provides an inheritance hook to all extended classes
      # Allows ou to hook into the inheritance
      def inherited(base)
        super
        _on_inherit.each{|b| b.call(base,self)}
      end

      # A hook to add code when the stack is inherited
      # The code will be executed when the class is inherited
      #
      # @example
      #   MyClass.on_inherit do |base, parent|
      #     # do stuff here between the child and parent
      #   end
      #
      # @api public
      # @author Daniel Neighman
      def on_inherit(&block)
        _on_inherit << block if block
        _on_inherit
      end
    end # OnInherit
  end # Hooks
end # Pancake
