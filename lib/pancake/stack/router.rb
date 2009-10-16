module Pancake
  class Stack
    class Router < Pancake::Router; end
    inheritable_inner_classes :Router
    cattr_writer :_router

    @_router = self::Router.new

    def self._router
      @_router ||= begin
        r = self::Router.new
        unless self == Pancake::Stack
          r.router = superclass._router.router.dup
        end
        r
      end
    end
    # Resets the router to use the stacks namespaced router.
    # This allows a router to mixin a module, and have that module
    # mixed in to child stacks/routers.  Effectively, this will reset the scope of inheritance so that a stack type can have particular route helpers
    #
    # When the router is rest, any routes declared in parent stacks will be lost.
    # @example
    #   MyStack.reset_router! # => Replaces the current router with MyStack::Router (instance)
    #
    # @api public
    def self.reset_router!
      self._router = self::Router.new
    end

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

