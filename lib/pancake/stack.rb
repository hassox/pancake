module Pancake
  class Stack
    extend  Rack::Router::Routable
    
    class << self
      attr_accessor :root
      
      def initialize_stack
        raise "Application root not set" if root.nil?
      end # initiailze stack
      
      def stack
        the_app = self
        Rack::Builder.new do
          run the_app
        end
      end # setup
    end # self
      
    def this_stack
      self.class
    end

  end # Stack
end # Pancake