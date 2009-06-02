class MyApp::Stack
  add_routes do |r|
    r.map "/",          :to => lambda{|e| self.foo},  :anchor => true
    r.map "/bar",       :to => MyApp::Bar,            :anchor => true
    r.map "/a_mount",   :to => MyMountedApp::Foo,     :anchor => true
  end
end