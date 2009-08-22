require File.dirname(__FILE__) + '/../../spec_helper'

describe "stack router" do
  before(:all) do
    clear_constants "FooApp" ,"INNER_APP"
  end
  before(:each) do
    
    ::INNER_APP = Proc.new{ |e| 
      [
        200, 
        {"Content-Type" => "text/plain"},
        [
          JSON.generate({
            "SCRIPT_NAME" => e["SCRIPT_NAME"],
            "PATH_INFO"   => e["PATH_INFO"], 
            "rack_router.params" => e["rack_router.params"]         
          })
        ]
      ]
    }
    class ::FooApp < Pancake::Stack
      def self.new_app_instance
        INNER_APP
      end
    end
    FooApp.roots << Pancake.get_root(__FILE__)
  end
  
  after(:each) do
    clear_constants "FooApp" ,"INNER_APP", "BarApp"
  end
  
  def app
    @app
  end
  
  it "should let me setup routes for the stack" do
    FooApp.add_routes do |r|
      r.map "/",    :to => INNER_APP, :with => {:action => "bar action"}, :anchor => true
      r.map "/foo", :to => INNER_APP, :with => {:action => "foo action"}, :anchor => true
    end
    
    @app = FooApp.stackup
    expected = {
      "SCRIPT_NAME" => "/foo",
      "PATH_INFO"   => "",
      "rack_router.params" => {"action" => "foo action"}
    }
    
    get "/foo"
    JSON.parse(last_response.body).should == expected
  end
  
  it "should pass through to the underlying application" do
    FooApp.add_routes do |r|
      r.map "/foobar", :to => Proc.new{|e| [200, {}, ["IN THE FOOBAR APP"]]}, :anchor => true
      r.map "/foo"  , :to => INNER_APP, :anchor => true
    end
    @app = FooApp.stackup
    get "/foobar"
    last_response.body.should == "IN THE FOOBAR APP"
    
    get "/some/route"
    JSON.parse(last_response.body).should == {
      "SCRIPT_NAME" => "",
      "PATH_INFO"   => "/some/route",
      "rack_router.params" => {}
    }
  end
  
  it "should let me prepend routes" do
    FooApp.add_routes do |r| 
      r.map "/:foo", :to => INNER_APP, :with => {:some => "foo"}, :anchor => true
    end
    
    FooApp.prepend_routes do |r|
      r.map "/:foo", :to => INNER_APP, :with => {:hah => "hah"}, :anchor => true
    end
    
    @app = FooApp.stackup
    get "/some_foo"
    JSON.parse(last_response.body).should == {
      "SCRIPT_NAME" => "/some_foo",
      "PATH_INFO"   => "",
      "rack_router.params" => {"hah" => "hah", "foo" => "some_foo"}
    }  
  end
  
  it "should allow me to inherit routes" do
    FooApp.add_routes do |r|
      r.map "/foo(/:stuff)", :to => INNER_APP, :with => {"originator" => "FooApp"}, :anchor => true
    end
    class BarApp < FooApp; end
    BarApp.add_routes do |r|
      r.map "/bar", :to => INNER_APP, :with => {"originator" => "BarApp"}, :anchor => true
    end
    
    @app = BarApp.stackup

    get "/bar"
    response = JSON.parse(last_response.body)
    response["rack_router.params"]["originator"].should == "BarApp"
    
    get "/foo/thing"
    response = JSON.parse(last_response.body)
    response["rack_router.params"]["originator"].should == "FooApp"
    
  end
  
  describe "Pancake route builder" do
    it "should allow me to mount an application" do
      FooApp.add_routes do |r|
        r.mount "/foo", INNER_APP, :action => "foo"
      end
      @app = FooApp.stackup
      get "/foo"
      result = JSON.parse(last_response.body)
      result["SCRIPT_NAME"].should == "/foo"
      result["rack_router.params"]["action"].should == "foo"
    end
  end
end