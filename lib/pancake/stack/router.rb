module Pancake
  class Stack
    class_inheritable_reader :router

    def self.router
      @router ||= Router.new
      yield @router if block_given?
      @router
    end
  end
end

