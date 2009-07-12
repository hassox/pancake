MyApp.add_routes do |r|
  r.map "/",          :to => lambda{|e| self.foo},  :anchor => true
  r.map "/bar",       :to => klass::Bar,            :anchor => true
  r.map "/baz",       :to => klass::Bar,            :anchor => true
  r.map "/a_mount",   :to => MyMountedApp::Foo,     :anchor => true
  r.map "/foo",       :to => Proc.new{|e|
    [200, {"Content-Type" => "text/plain", "Content-Length" => "3"}, ["foo"]]
  }
  r.map "/some",      :to => SomeMount.stackup
  
  r.map "/sinatra/one", :to => SinatraOne
  r.map "/sinatra/two", :to => SinatraTwo
  
  # ::ActionController::Base.relative_url_root = "/rails"
  # r.map "/rails",       :to => ::ActionController::Dispatcher.new($stdout) 
  r.mount_rails "/man/im/in/rails"
end