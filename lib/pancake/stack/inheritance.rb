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
      on_inherit.each{|blk| blk.call(base)}
    end
  end # Stack
end # Pancake