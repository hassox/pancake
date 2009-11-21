require File.join(File.expand_path(File.dirname(__FILE__)),'..', '..', '..', 'spec_helper')

describe Pancake::Stacks::Short, "routes" do
  before do
    class ::RoutedShortStack < Pancake::Stacks::Short
      roots << Pancake.get_root(__FILE__)

      get "/", :_name => :root do
        "get - /"
      end

      get "/foo", :_name => :foo do
        "get - foo"
      end

      get "/bar", :_name => :bar do
        "get - bar"
      end

      post "/foo" do
        "post - foo"
      end

      post "/bar" do
        "post - bar"
      end

      put "/foo" do
        "put - foo"
      end

      put "/bar" do
        "put - bar"
      end

      delete "/foo" do
        "delete - foo"
      end

      delete "/bar" do
        "delete - bar"
      end

      any "/any/foo" do
        "any - foo"
      end

      get "/baz/:var(/:date)" do
        "done: var == #{params[:var]} : date == #{params[:date]}"
      end.name(:baz)
    end
    @app = RoutedShortStack.stackup
  end
  after do
    clear_constants "RoutedShortStack", "FooApp", "BarApp"
  end

  def app
    @app
  end

  %w(foo bar).each do |item|
    %w(get post put delete).each do |method|
      it "should #{method} /#{item}" do
        result = self.send(method, "/#{item}")
        result.status.should == 200
        result.body.should == "#{method} - #{item}"
      end
    end # get post put delete
  end # foo bar

  it "should return a not found if we try to get an action that has not been defined" do
    result = get "/blah"
    result.status.should == 404
  end


  it "should handle tricky routes" do
    result = get "/baz/hassox"
    result.status.should == 200
    result.body.should == "done: var == hassox : date == "
  end

  it "should handle tricky routes with optional parameters" do
    result = get "/baz/hassox/2009-08-21"
    result.status.should == 200
    result.body.should == "done: var == hassox : date == 2009-08-21"
  end

  it "should handle the any request method" do
    [:get, :post, :put, :delete].each do |meth|
      result = self.send(meth, "/any/foo")
      result.status.should == 200
      result.body.should == "any - foo"
    end
  end

  describe "url generation" do
    it "should generate a simple named  url" do
      Pancake.url(RoutedShortStack, :foo).should == "/foo"
    end

    it "should generate a complex named  url" do
      Pancake.url(RoutedShortStack, :baz, :var => "bar").should == "/baz/bar"
      Pancake.url(RoutedShortStack, :baz, :var => "bar", :date => "today").should == "/baz/bar/today"
    end

    it "should generate it's url when it's nested" do
      class ::FooApp < Pancake::Stack; end
      FooApp.router.mount(RoutedShortStack, "/short/stack")
      FooApp.router.mount_applications!
      Pancake.url(RoutedShortStack, :foo).should == "/short/stack/foo"
      Pancake.url(RoutedShortStack, :baz, :var => "var", :date => "today").should == "/short/stack/baz/var/today"
    end
  end

  describe "inherited route generation" do
    before do
      class ::FooApp < RoutedShortStack; end
      @app = FooApp.stackup
    end

    it "should generate an inherited simple url" do
      Pancake.url(FooApp, :foo).should == "/foo"
    end

    it "should generate a complex url" do
      Pancake.url(FooApp, :baz, :var => "the_var", :date => "today").should == "/baz/the_var/today"
    end

    %w(foo bar).each do |item|
      %w(get post put delete).each do |method|
        it "should #{method} /#{item}" do
          result = self.send(method, "/#{item}")
          result.status.should == 200
          result.body.should == "#{method} - #{item}"
        end
      end # get post put delete
    end # foo bar

    it "should match the nested route without affecting the parent" do
      class ::BarApp < Pancake::Stack; end
      BarApp.router.mount(FooApp, "/mount/point")
      BarApp.router.mount_applications!

      Pancake.url(FooApp, :foo).should == "/mount/point/foo"
      Pancake.url(RoutedShortStack, :foo).should == "/foo"
    end
  end
end
