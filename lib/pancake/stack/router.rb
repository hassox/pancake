module Pancake
  class Stack
    class Router < Pancake::Router; end
    inheritable_inner_classes :Router

    class_inheritable_accessor :_router
    @_router = self::Router.new

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

