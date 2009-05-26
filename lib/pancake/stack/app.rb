module Pancake
  class Stack
    # get a new instance of the application for this stack
    # Ovewrite this to provide custom application initialization
    # :api: overwritable
    def self.new_app_instance
      self.new
    end
    
    def call(env)
      Pancake::OK_APP.call(env)
    end
  end # Pancake
end # Pancake