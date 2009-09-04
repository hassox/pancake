module Pancake
  class Stack
    class_inheritable_accessor :router
    @router = Pancake::Router.new
    
    def self.with_router(config_label=self)
      yield router if block_given?
      router
    end
    
  end
end

