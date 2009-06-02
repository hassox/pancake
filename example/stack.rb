module MyApp
  class Stack < Pancake::Stack
    add_routes do |r|
      r.map "/foo", :to => Proc.new{|e|
        [200, {"Content-Type" => "text/plain", "Content-Length" => "3"}, ["foo"]]
      }
    end
  end
end