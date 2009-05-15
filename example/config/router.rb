class MyApp::Stack
  prepare do |r|
    r.map "/",          :to => lambda{|e| self.foo},  :anchor => true
    r.map "/bar",       :to => MyApp::Bar
    r.map "/a_mount",   :to => MyMountedApp::Foo
    # r.map "/nested_deeply", :to => NestedDeeply::Foo, :anchor => true # This should not work
  end
end