require File.dirname(__FILE__) + '/../../../spec_helper'

describe Pancake::Stacks::Short, "routes" do
  before do
    class ::RoutedShortStack < Pancake::Stacks::Short
      roots << Pancake.get_root(__FILE__)

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

      get "/baz/:var(/:date)" do
        "done: var == #{params[:var]} : date == #{params[:date]}"
      end.name(:baz)
    end
    @app = RoutedShortStack.stackup
  end
  after do
    clear_constants "RoutedShortStack"
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

  describe "url generation" do
    it "should generate a simple named  url" do
      Pancake.url(RoutedShortStack, :foo).should == "/foo"
    end

    it "should generate a complex named  url" do
      Pancake.url(RoutedShortStack, :baz, :var => "bar").should == "/baz/bar"
      Pancake.url(RoutedShortStack, :baz, :var => "bar", :date => "today").should == "/baz/bar/today"
    end
  end
end
