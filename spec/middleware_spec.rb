require File.dirname(__FILE__) + '/spec_helper'

describe "Pancake::Middleware" do
  include Rack::Test::Methods
  
  def app
    FooApp.stack
  end
  
  def default_env
    Rack::MockRequest.env_for
  end
  
  before(:each) do
    $current_env = {}
    Object.class_eval {remove_const("GeneralMiddleware") if defined?(GeneralMiddleware)}
    Object.class_eval {remove_const("FooApp") if defined?(FooApp)}
    Object.class_eval {remove_const("FooMiddle") if defined?(FooMiddle)}
    Object.class_eval {remove_const("BarMiddle") if defined?(BarMiddle)}

    class GeneralMiddleware
      attr_accessor :app
      def initialize(app, opts={});@app = app; end
      
      def mark_env(env)
        env["pancake.spec.captures"] ||= []
        env["pancake.spec.captures"] << self.class.name
      end
      
      def call(env)
        mark_env(env)
        @app.call(env)
      end
    end # GeneralMiddlware
    
    class FooApp
      extend Pancake::Middleware
      def call(env)
        $current_env = env
        [200,{"Content-Type" => "text/plain"}, ["FooApp"]]
      end
    end # FooApp
  end 
  
  it "should allow me to add middleware" do
    FooApp.class_eval do
      use GeneralMiddleware
    end
    get "/"
    $current_env["pancake.spec.captures"].should include("GeneralMiddleware")
  end
  
  it "should allow me to add multiple middlewares" do
    class FooMiddle < GeneralMiddleware; end
    FooApp.class_eval do
      use GeneralMiddleware
      use FooMiddle
    end
    get "/"
    %w(GeneralMiddleware FooMiddle).each do |m|
      $current_env["pancake.spec.captures"].should include(m)
    end
  end
  
  it "should prepend middlewares" do
    class FooMiddle < GeneralMiddleware; end
    class BarMiddle < GeneralMiddleware; end
    
    FooApp.class_eval do
      use GeneralMiddleware
      use FooMiddle
      prepend_use BarMiddle
    end
    get "/"
    $current_env["pancake.spec.captures"].should == ["BarMiddle", "GeneralMiddleware", "FooMiddle"]  
  end
  
  it "should allow you to add middleware from outside the class" do
    FooApp.use GeneralMiddleware
    get "/"
    $current_env["pancake.spec.captures"].should == ["GeneralMiddleware"]
  end
  
end