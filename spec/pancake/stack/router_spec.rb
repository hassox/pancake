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
            "usher.params" => e["usher.params"]
          })
        ]
      ]
    }
    class ::FooApp < Pancake::Stack; end
    FooApp.roots << Pancake.get_root(__FILE__)
  end

  after(:each) do
    clear_constants "FooApp" ,"INNER_APP", "BarApp"
  end

  def app
    @app
  end

  describe "mount" do
    it "should let me setup routes for the stack" do
      FooApp.with_router do |r|
        r.mount(INNER_APP, "/foo", :action => "foo action").name(:foo)
        r.mount(INNER_APP, "/bar", :action => "bar action").name(:root)
      end

      @app = FooApp.stackup
      expected = {
        "SCRIPT_NAME" => "/foo",
        "PATH_INFO"   => "",
        "usher.params" => {"action" => "foo action"}
      }

      get "/foo"
      JSON.parse(last_response.body).should == expected
    end

    it "should allow me to stop the route from partially matching" do
      FooApp.with_router do |r|
        r.mount(INNER_APP, "/foo/bar", :action => "foo/bar", :_exact => true).name(:foobar)
      end
      @app = FooApp.stackup
      expected = {
        "SCRIPT_NAME"   => "/foo/bar",
        "PATH_INFO"     => "",
        "usher.params"  => {"action" => "foo/bar"}
      }
      get "/foo/bar"
      JSON.parse(last_response.body).should == expected
      get "/foo"
      last_response.status.should == 404
    end

    it "should make sure that the application is a rack application" do
      lambda do
        FooApp.router.mount(:not_an_app, "/foo")
      end.should raise_error(Pancake::Router::RackApplicationExpected)
    end
  end

  describe "internal stack routes" do
    it "should pass through to the underlying app when adding a route" do
      FooApp.router.add("/bar", :action => "bar").name(:gary)
      class ::FooApp
        def self.new_app_instance
          INNER_APP
        end
      end

      @app = FooApp.stackup
      get "/bar"
      result = JSON.parse(last_response.body)
      result["usher.params"].should == {"action" => "bar"}
    end

    it "should add the usher.params to the request params" do
      app = mock("app", :call => Rack::Response.new("OK").finish, :null_object => true)
      app.should_receive(:call).with do |e|
        params = Rack::Request.new(e).params
        params[:action].should == "jackson"
      end
      FooApp.router.mount(app, "/foo/app", :action => "jackson")
      @app = FooApp.stackup
      get "/foo/app"
    end
  end

 # it "should allow me to inherit routes" do
 #   FooApp.add_routes do |r|
 #     r.map "/foo(/:stuff)", :to => INNER_APP, :with => {"originator" => "FooApp"}, :anchor => true
 #   end
 #   class BarApp < FooApp; end
 #   BarApp.add_routes do |r|
 #     r.map "/bar", :to => INNER_APP, :with => {"originator" => "BarApp"}, :anchor => true
 #   end
 #
 #   @app = BarApp.stackup
 #
 #   get "/bar"
 #   response = JSON.parse(last_response.body)
 #   response["rack_router.params"]["originator"].should == "BarApp"
 #
 #   get "/foo/thing"
 #   response = JSON.parse(last_response.body)
 #   response["rack_router.params"]["originator"].should == "FooApp"
 #
 # end
end
