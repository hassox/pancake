require File.dirname(__FILE__) + '/../../spec_helper'

describe Pancake::Middlewares::Static do
  before do
    @app = lambda{|e| Rack::Response.new("OK").finish}
    class ::FooBar < Pancake::Stack; end

    FooBar.roots << File.join(File.expand_path(File.dirname(__FILE__)), "../fixtures/middlewares")
    FooBar.push_paths(:public, ["public", "other_public"])
  end

  after do
    clear_constants :FooBar
  end

  it "should require a stack to be passed to initialize" do
    static = Pancake::Middlewares::Static.new(@app, FooBar)
    static.stack.should == FooBar
  end

  it "should raise an error if not initialized with an object that includes Pancake::Paths" do
    lambda do
      Pancake::Middlewares::Static.new(@app, Object)
    end.should raise_error
  end

  it "should return the file if one is found in the first root" do
    static = Pancake::Middlewares::Static.new(@app, FooBar)
    env = Rack::MockRequest.env_for("/one.html")
    result = static.call(env)
    result[0].should == 200
    body = result[2].body.map{|e| e}.join
    body.should include("In One")
  end

  it "should return the file if one is found in any of the roots" do
    static = Pancake::Middlewares::Static.new(@app, FooBar)
    env = Rack::MockRequest.env_for("/two.html")
    result = static.call(env)
    result[0].should == 200
    body = result[2].body.map{|e| e}.join
    body.should include("In Two")
  end

  it "should pass through to the application if there is no file found" do
    static = Pancake::Middlewares::Static.new(@app, FooBar)
    env = Rack::MockRequest.env_for("/not_here.html")
    result = static.call(env)
    result[0].should == 200
    body = result[2].body.map{|e| e}.join
    body.should == "OK"
  end
end
