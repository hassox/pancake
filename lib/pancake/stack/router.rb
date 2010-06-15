module Pancake
  class Stack
    inheritable_inner_classes :Router
    class Router < Pancake::Router; end

    def self.router
      @router ||= begin
        if superclass.respond_to?(:router) && superclass.router
          r = superclass.router.clone(self::Router)
          r.stack = self
        else
          r = self::Router.new
          r.stack = self
        end
        yield r if block_given?
        r
      end
    end
  end
end

