class MyApp < Pancake::Stack
  
  prepare do |r|
    r.map "/", :to => lambda{|e| self.foo}
  end
  
  def self.foo
    [200, {"Content-Type" => "text/html"}, "The root is #{self.root}"]
  end
  
end