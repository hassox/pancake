module MyApp
  class Stack < Pancake::Stack
    
    def self.new_app_instance
      MyApp::Bar
    end
    
  end
end