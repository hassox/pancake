module MyApp
  class Stack < Pancake::Stack
    add_routes do |r|
      r.map "/foo", :to => Proc.new{|e|
        [200, {"Content-Type" => "text/plain", "Content-Length" => "3"}, ["foo"]]
      }
    end
    
    def self.new_app_instance
      MyApp::Bar
    end
    
  end
end