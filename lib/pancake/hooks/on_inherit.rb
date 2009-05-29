module Pancake
  module Hooks
    module OnInherit
      def self.extended(base)
        base.class_eval do
          class_inheritable_reader :_on_inherit
          @_on_inherit = []
        end
      end
    
      # Provides an inheritance hook to all extended classes
      # Allows ou to hook into the inheritance 
      # :api: public
      def inherited(base)
        super
        _on_inherit.each{|b| b.call(base,self)}
      end
    
      # A hook to add code when the stack is inherited
      # :api: public
      def on_inherit(&block)
        _on_inherit << block if block
        _on_inherit
      end
    end # OnInherit
  end # Hooks
end # Pancake