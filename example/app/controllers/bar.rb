class MyApp
  class Bar
    def self.call(env)
      [200, {"Content-Type" => "text/html", "Content-Length" => "6"}, "In Bar"]
    end
  end
  
end # MyApp