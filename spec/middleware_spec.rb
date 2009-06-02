require File.dirname(__FILE__) + '/spec_helper'

describe "Pancake::Middleware" do
  include Rack::Test::Methods
  
  before(:each) do
    def app
      @app
    end

    def default_env
      Rack::MockRequest.env_for
    end

    $current_env = {}
    Object.class_eval {remove_const("GeneralMiddleware") if defined?(::GeneralMiddleware)}
    Object.class_eval {remove_const("FooApp") if defined?(::FooApp)}
    Object.class_eval {remove_const("BarApp") if defined?(::BarApp)}
    Object.class_eval {remove_const("BazApp") if defined?(::BazApp)}
    Object.class_eval {remove_const("FooMiddle") if defined?(::FooMiddle)}
    Object.class_eval {remove_const("BarMiddle") if defined?(::BarMiddle)}

    class ::GeneralMiddleware
      attr_accessor :app
      def initialize(app, opts={});@app = app; end
      
      def mark_env(env)
        env["pancake.spec.captures"] ||= []
        env["pancake.spec.captures"] << self.class
      end
      
      def call(env)
        mark_env(env)
        @app.call(env)
      end
    end # GeneralMiddlware
    
    class ::FooApp < Pancake::Stack
      def self.new_app_instance; self.new; end
      
      def call(env)
        $current_env = env
        [200,{"Content-Type" => "text/plain"}, ["FooApp"]]
      end
    end # FooApp
  end 
  
  after(:each) do
    clear_constants(:GeneralMiddleware, :FooApp, :BarMiddle, :FooMiddle, :BarApp, :BazApp)
  end
  
  it "should allow me to add middleware" do
    FooApp.class_eval do
      use GeneralMiddleware
    end
    @app = FooApp.stack
    get "/"
    $current_env["pancake.spec.captures"].should include(GeneralMiddleware)
  end
  
  it "should allow me to add multiple middlewares" do
    class ::FooMiddle < GeneralMiddleware; end
    FooApp.class_eval do
      use GeneralMiddleware
      use FooMiddle
    end
    @app = FooApp.stack
    get "/"
    [GeneralMiddleware, FooMiddle].each do |m|
      $current_env["pancake.spec.captures"].should include(m)
    end
  end
  
  it "should prepend middlewares" do
    class ::FooMiddle < GeneralMiddleware; end
    class ::BarMiddle < GeneralMiddleware; end
    
    FooApp.class_eval do
      use GeneralMiddleware
      use FooMiddle
      prepend_use BarMiddle
    end
    @app = FooApp.stack
    get "/"
    $current_env["pancake.spec.captures"].should == [BarMiddle, GeneralMiddleware, FooMiddle]  
  end
  
  it "should allow you to add middleware from outside the class" do
    FooApp.use GeneralMiddleware
    @app = FooApp.stack
    get "/"
    $current_env["pancake.spec.captures"].should == [GeneralMiddleware]
  end
  
  describe "Inherited middleware" do
    before(:each) do
      class FooMiddle < GeneralMiddleware; end
      class BarMiddle < GeneralMiddleware; end
    end
    
    it "should inherit middleware from it's parent class" do
      FooApp.use GeneralMiddleware
      FooApp.use FooMiddle
      class BarApp < FooApp; end
      BarApp.middlewares.should == FooApp.middlewares
    end
    
    it "should not pollute the parent when including new middlewares in the child" do
      FooApp.use GeneralMiddleware
      class BarApp < FooApp; end
      BarApp.use FooMiddle
      BarApp.middlewares.map{|m| m.middleware}.should == [GeneralMiddleware, FooMiddle]
      FooApp.middlewares.map{|m| m.middleware}.should == [GeneralMiddleware]
    end
    
    it "should inherit multiple children deep" do
      FooApp.use GeneralMiddleware
      class BarApp < FooApp; end
      BarApp.prepend_use FooMiddle
      class BazApp < BarApp; end
      BazApp.use BarMiddle
      FooApp.middlewares.map{|m| m.middleware}.should == [GeneralMiddleware]
      BarApp.middlewares.map{|m| m.middleware}.should == [FooMiddle, GeneralMiddleware]
      BazApp.middlewares.map{|m| m.middleware}.should == [FooMiddle, GeneralMiddleware, BarMiddle]
    end
  end
  
  describe "Stacks should inherit middleware" do
    before(:all) do
      $pk_middlewares = Pancake::Stack.middlewares.dup
    end
    
    after(:all) do
      Pancake::Stack.middlewares.replace $pk_middlewares
    end
    
    before(:each) do
      class FooMiddle < GeneralMiddleware; end
      class BarMiddle < GeneralMiddleware; end
    end
    
    after(:each) do
      Pancake::Stack.middlewares.clear
    end
    
    it "should clear the middlewares for the specs" do
      Pancake::Stack.middlewares.should be_blank
    end
    
    it "should allow me to set middlewares on Pancake::Stack" do
      Pancake::Stack.use GeneralMiddleware
      Pancake::Stack.middlewares.map{|m| m.middleware}.should == [GeneralMiddleware]
    end
    
    it "should carry down middlewares from the Pancake::Stack to inherited stacks" do
      Pancake::Stack.use GeneralMiddleware
      class FooApp < Pancake::Stack; end
      FooApp.use FooMiddle
      Pancake::Stack.middlewares.map{|m| m.middleware}.should == [GeneralMiddleware]
      FooApp.middlewares.map{|m| m.middleware}.should == [GeneralMiddleware, FooMiddle]
    end
    
    it "should let me have different middlewares in different children" do
      Pancake::Stack.use GeneralMiddleware
      class FooApp < Pancake::Stack; end
      FooApp.use FooMiddle
      class BarApp < Pancake::Stack; end
      BarApp.use BarMiddle
      FooApp.middlewares.map{|m| m.middleware}.should == [GeneralMiddleware, FooMiddle]
      BarApp.middlewares.map{|m| m.middleware}.should == [GeneralMiddleware, BarMiddle]
    end
  end # Stack Inheritance
  
end