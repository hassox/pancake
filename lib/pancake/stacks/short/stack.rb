module Pancake
  module Stacks
    class Short < Pancake::Stack
      
      def self.new_app_instance
        Controller
      end
      
    end # Short
  end # Stacks
end # Pancake