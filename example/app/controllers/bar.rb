module MyApp
  class Bar
    def self.call(env)
      [200, {"Content-Type" => "text/html"}, "In Bar"]
    end
  end
end