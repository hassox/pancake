class Pancake
  module Matchers
    
    class InheritFrom
      def initialize(expected)
        @expected = expected
      end
      
      def matches?(target)
        @target = target
        @target.ancestors.include?(@expected)
      end
      
      def failure_message
        "expected #{@target} to inherit from #{@expected} but did not"
      end
    end
    
    def inherit_from(expected)
      InheritFrom.new(expected)
    end
    
    
  end # Matchers
end # Pancake