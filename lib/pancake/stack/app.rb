module Pancake
  class Stack

    class << self
      
      # get a new instance of the application for this stack
      # Ovewrite this to provide custom application initialization
      # :api: overwritable
      def new_app_instance
        new        
      end
      
    end # self
    
  end # Pancake
end # Pancake