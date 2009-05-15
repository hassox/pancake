module MyApp
  class Stack < Pancake::Stack    
    
    def self.foo
      [200, {"Content-Type" => "text/html"}, "The root is #{self.root}"]
    end
  end
end