module Pancake
  class Stack
    # get a new instance of the application for this stack
    # Ovewrite this to provide custom application initialization
    # :api: overwritable
    def self.new_app_instance
      OK_APP 
    end    
  end # Pancake
end # Pancake