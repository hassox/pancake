module Pancake
  class Stack
    class_inheritable_accessor :_router
    @_router = Pancake::Router.new
    
    def self.router
      yield _router if block_given?
      _router
    end
    
    def self.with_router
      yield router if block_given?
      router
    end

  end
end

