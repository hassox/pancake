require File.dirname(__FILE__) + '/../../spec_helper'

describe "stack router" do
  before(:all) do
    clear_constants "FooApp" ,"INNER_APP", "BarApp", "InnerApp", "InnerFoo", "InnerBar"
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
      FooApp.router do |r|
        r.mount(INNER_APP, "/foo", :_defaults => {:action => "foo action"}).name(:foo)
        r.mount(INNER_APP, "/bar", :_defaults => {:action => "bar action"}).name(:root)
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
          r.mount(INNER_APP, "/foo/bar", :_defaults => {:action => "foo/bar"}, :_exact => true).name(:foobar)
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

    it "should not match a single segment route when only / is defined" do
      FooApp.router.add("/", :_defaults => {:root => :var}) do |e|
        Rack::Response.new("In the Root").finish
      end
      @app = FooApp.stackup
      result = get "/not_a_route"
      result.status.should == 404
    end

    describe "mounting stacks" do
      before do
        @stack_app = lambda{|e| Rack::Response.new("stacked up").finish}
      end

      it "should not imediately stackup the passed in resource" do
        stack = mock("stack")
        stack.should_not_receive(:stackup)
        FooApp.router.mount(stack, "/stackup")
      end

      it "should stackup a class if it responds to stackup" do
        stack = mock("stack")
        stack.should_receive(:stackup).and_return(@stack_app)
        FooApp.router.mount(stack, "/stackup")

        @app = FooApp.stackup
        result = get "/stackup"
        result.body.should include("stacked up")
      end

      it "should activate the class with the activate option" do

      end

      it "should pass the given args to the class to create it" do

      end
    end
  end

  describe "generating routes" do
    before do
      FooApp.router do |r|
        r.add("/simple/route"    ).name(:simple)
        r.add("/var/with/:var", :_defaults => {:var => "some_var"}).name(:defaults)
        r.add("/complex/:var"    ).name(:complex)
        r.add("/optional(/:var)" ).name(:optional)
        r.add("/some/:unique_var")
        r.add("/", :_defaults => {:var => "root var"}).name(:root)
      end
    end

    it "should allow me to generate a named route for a stack" do
      Pancake.url(FooApp, :simple).should == "/simple/route"
    end

    it "should allow me to generate a non-named route for a stack" do
      Pancake.url(FooApp, :complex, :var => "a_variable").should == "/complex/a_variable"
    end

    it "should allow me to generate a route with values" do
      Pancake.url(FooApp, :optional).should == "/optional"
      Pancake.url(FooApp, :optional, :var => "some_var").should == "/optional/some_var"
    end

    it "should allow me to generate routes with defaults" do
      Pancake.url(FooApp, :defaults).should == "/var/with/some_var"
      Pancake.url(FooApp, :defaults, :var => "this_is_a_var").should == "/var/with/this_is_a_var"
    end

    it "should allow me to generate a route by params" do
      Pancake.url(FooApp, :unique_var => "unique_var").should == "/some/unique_var"
    end

    it "should generate a base url of '/' for the top level router" do
      FooApp.router.base_url.should == "/"
    end

    describe "mounted route generation" do
      before do
        class ::BarApp < Pancake::Stack; end
        BarApp.roots << Pancake.get_root(__FILE__)
        BarApp.router do |r|
          r.add("/simple").name(:simple)
          r.add("/some/:var", :_defaults => {:var => "foo"}).name(:foo)
        end
        FooApp.router.mount(BarApp, "/bar")
        FooApp.router.mount_applications!
        FooApp.stackup
      end

      it "should allow me to generate a simple nested named route" do
        Pancake.url(BarApp, :simple).should == "/bar/simple"
      end

      it "should allow me to generate a simple nested named route for a named app" do
        FooApp.router.mount(BarApp, "/different", :_args => [{:app_name => :bar_app}])
        FooApp.router.mount_applications!
        Pancake.url(:bar_app, :simple).should == "/different/simple"
        Pancake.url(BarApp,   :simple).should == "/bar/simple"
      end

      it "should generate the base url for a mounted application" do
        BarApp.configuration.router.base_url.should == "/bar"
      end

      it "should generate a base url for a named application" do
        Pancake.base_url_for(BarApp)
      end
    end

  end

  describe "internal stack routes" do
    it "should pass through to the underlying app when adding a route" do
      FooApp.router.add("/bar", :_defaults => {:action => "bar"}).name(:gary)
      class ::FooApp
        def self.new_app_instance
          INNER_APP
        end
      end
      FooApp.router.mount(INNER_APP, "/some_mount")

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
      FooApp.router.mount(app, "/foo/app", :_defaults => {:action => "jackson"})
      @app = FooApp.stackup
      get "/foo/app"
    end
  end

  it "should allow me to inherit routes" do
    FooApp.router do |r|
      r.mount(INNER_APP, "/foo(/:stuff)", :_defaults => {"originator" => "FooApp"})
    end
    class ::BarApp < FooApp; end
    BarApp.router do |r|
      r.mount(INNER_APP, "/bar", :_defaults => {"originator" => "BarApp"})
    end

    @app = BarApp.stackup

    get "/bar"
    response = JSON.parse(last_response.body)
    response["usher.params"]["originator"].should == "BarApp"

    get "/foo/thing"
    response = JSON.parse(last_response.body)
    response["usher.params"]["originator"].should == "FooApp"
  end

  it "should generate an inherited route" do
    FooApp.router do |r|
      r.add("/simple").name(:simple)
      r.mount(INNER_APP, "/foo(/:stuff)").name(:stuff)
    end

    class ::BarApp < FooApp; end
    FooApp.router.mount_applications!

    Pancake.url(BarApp, :simple).should == "/simple"
    Pancake.url(BarApp, :stuff => "this_stuff").should == "/foo/this_stuff"
    Pancake.url(BarApp, :stuff, :stuff => "that_stuff").should == "/foo/that_stuff"
  end

  it "should put the configuration into the env" do
    FooApp.router.add("/foo").to do |e|
      e["pancake.request.configuration"].should == Pancake.configuration.configs[FooApp]
      Rack::Response.new("OK").finish
    end
    @app = FooApp.stackup
    get "/foo"
  end

  it "should inherit the router as an inherited inner class" do
    class ::BarApp < FooApp; end
    BarApp::Router.should inherit_from(FooApp::Router)
  end

  it "should inherit the router class as an inner class" do
    class ::BarApp < FooApp; end
    FooApp.router.class.should == FooApp::Router
    BarApp.router.class.should == BarApp::Router
  end

  it "should reset the router to the namespaced router" do
    class ::BarApp < FooApp; end
    BarApp.reset_router!
    BarApp.router.class.should == BarApp::Router
  end


  describe "generating urls inside an application" do
    before do
      class ::BarApp < FooApp;  end

      class ::InnerApp
        attr_reader :env
        include Pancake::Mixins::RequestHelper

        def self.app_block(&block)
          if block_given?
            @app_block = block
          end
          @app_block
        end

        def call(env)
          @env = env
          instance_eval &self.class.app_block
          Rack::Response.new("OK").finish
        end
      end

      class ::FooApp; def self.new_app_instance; InnerApp.new; end; end

      BarApp.router do |r|
        r.add("/mounted")
        r.add("/foo").name(:foo)
        r.add("/other").name(:other)
      end

      FooApp.router do |r|
        r.mount(BarApp, "/bar")
        r.add(  "/foo"   ).name(:foo)
        r.add(  "/simple").name(:simple)
      end

      @app = FooApp.stackup
    end

    it "should generate the urls correctly" do
      InnerApp.app_block do
        url(:foo).should == "/foo"
        url(:simple).should == "/simple"
      end

      get "/foo"
    end

    it "should generate urls correctly when nested" do
      InnerApp.app_block do
        url(:foo).should == "/bar/foo"
        url(:other).should == "/bar/other"
      end
      get "/bar/mounted"
    end

    it "should generate a url for another app" do
      InnerApp.app_block do
        url_for(BarApp, :foo).should == "/bar/foo"
        url_for(FooApp, :foo).should == "/foo"
      end
      get "/foo"
    end
  end
end
