module Pancake
  class Stack    
    # A hook to add code when the stack is inherited
    # :api: public
    def self.on_inherit(&block)
      @on_inherit ||= []
      @on_inherit << block if block
      @on_inherit
    end
    
    # Call back any registed code on inhertied
    # :api: private
    def self.inherited(base)
      ::Pancake::Stack.on_inherit.each{|blk| blk.call(base, self)}
    end
  end # Stack
end # Pancake


## Add the inherit hooks to inherited classes
Pancake::Stack.on_inherit do |base, parent|
  base.class_eval do
    def self.inherited(new_base)
      ::Pancake::Stack.on_inherit.each{|blk| blk.call(new_base, self)}
    end
  end
end