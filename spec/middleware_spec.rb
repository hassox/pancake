require File.dirname(__FILE__) + '/spec_helper'

describe "Pancake::Middleware" do
  before(:all) do
    $pk_mid = Pancake.middlewares.dup
  end
  
  after(:all) do
    Pancake.middlewares.replace $pk_mid
  end
  
  before(:each) do
    Pancake.middlewares.clear
    def app
      @app
    end

    def default_env
      Rack::MockRequest.env_for
    end

    $current_env = {}
    
    class ::GeneralMiddleware
      attr_accessor :app
      def initialize(app, opts={});@app = app; end
      
      def mark_env(env)
        env["p.s.c"] ||= []
        env["p.s.c"] << self.class
      end
      
      def call(env)
        mark_env(env)
        @app.call(env)
      end
    end # GeneralMiddlware
    
    class ::FooApp < Pancake::Stack
      def self.new_app_instance; self end
      
      def self.call(env)
        $current_env = env
        [200,{"Content-Type" => "text/plain"}, ["FooApp"]]
      end
    end # FooApp
    FooApp.roots << Pancake.get_root("/tmp")
  end 
  
  after(:each) do
    clear_constants(:FooApp, :BarApp, :BazApp, :GeneralMiddleware, :BarMiddle, :FooMiddle, :BazMiddle, :PazMiddle)
  end
  
  describe "pancake middlewares" do
    before(:each) do
      @root = File.join(Pancake.get_root(__FILE__), "fixtures", "foo_stack")
      @the_app = Proc.new{|e| }
      Pancake::StackMiddleware.reset!
    end
    
    it "should allow me to add middleware to pancake" do
      Pancake.use GeneralMiddleware
      @app = Pancake.start(:root => @root){ FooApp.stackup }
      Pancake.middlewares.map{|m| m.middleware}.should == [GeneralMiddleware]
      get "/"
      $current_env["p.s.c"].should include(GeneralMiddleware)
    end
    
    it "should allow me to add multiple middlewares to panckae" do
      class ::FooMiddle < GeneralMiddleware; end
      Pancake.use GeneralMiddleware
      FooApp.use  FooMiddle
      @app = Pancake.start(:root => @root){ FooApp.stackup }
      get "/"
      $current_env["p.s.c"].should == [GeneralMiddleware, FooMiddle]
    end

    it "should put the pancake middlewares out in front" do
      class ::FooMiddle < GeneralMiddleware; end
      class ::BarMiddle < GeneralMiddleware; end
      class ::BarApp < FooApp; end
      class ::BazApp < FooApp; end
            
      BarApp.use BarMiddle
      BazApp.use FooMiddle
      Pancake.use GeneralMiddleware

      FooApp.add_routes do |r|
        r.map "/bar", :to => BarApp.stackup, :anchor => true
        r.map "/baz", :to => BazApp.stackup, :anchor => true
      end
      BarApp.stack_routes.clear
      BazApp.stack_routes.clear
      
      @app = Pancake.start(:root => @root){ FooApp.stackup }
      get "/baz"
      $current_env["p.s.c"].should == [GeneralMiddleware, FooMiddle]
      get "/bar"
      $current_env["p.s.c"].should == [GeneralMiddleware, BarMiddle]
    end
  end
  
  it "should allow me to add middleware" do
    FooApp.class_eval do
      use GeneralMiddleware
    end
    @app = FooApp.stackup
    get "/"
    $current_env["p.s.c"].should include(GeneralMiddleware)
  end
  
  it "should allow me to add multiple middlewares" do
    class ::FooMiddle < GeneralMiddleware; end
    FooApp.class_eval do
      use GeneralMiddleware
      use FooMiddle
    end
    @app = FooApp.stackup
    get "/"
    [GeneralMiddleware, FooMiddle].each do |m|
      $current_env["p.s.c"].should include(m)
    end
  end
  
  it "should prepend middlewares" do
    pending("Have not re-implemented prepend yet") do
      class ::FooMiddle < GeneralMiddleware; end
      class ::BarMiddle < GeneralMiddleware; end
    
      FooApp.class_eval do
        use GeneralMiddleware
        use FooMiddle
        prepend_use BarMiddle
      end
      @app = FooApp.stackup
      get "/"
      $current_env["p.s.c"].should == [BarMiddle, GeneralMiddleware, FooMiddle]  
    end
  end
  
  it "should allow you to add middleware from outside the class" do
    FooApp.use GeneralMiddleware
    @app = FooApp.stackup
    get "/"
    $current_env["p.s.c"].should == [GeneralMiddleware]
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
      pending("No prepend use yet") do
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
      Pancake::Stack::StackMiddleware.reset!
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
    
    describe "Stack Middleware Enabled Constant", :shared => true do
      
      before(:each) do
        raise "You must set a @konstant for the stack construction spec" unless @konstant
        @konstant::StackMiddleware.reset!
      end
      
      describe "named middleware" do
        it "should allow me to name a #{@konstant} middleware" do
          @konstant.stack(:foo).use(GeneralMiddleware)
          @konstant.stack[:foo].middleware.should == GeneralMiddleware
        end
        
        it "should implicitly name a middleware" do
          @konstant.stack.use(GeneralMiddleware)
          @konstant.stack[GeneralMiddleware].middleware.should == GeneralMiddleware
        end        
      end
      
      describe "before/after middleware" do
        before(:each) do
          class ::BazMiddle < GeneralMiddleware; end
          class ::PazMiddle < GeneralMiddleware; end
        end
        # :FooApp, :BarApp, :BazApp, :GeneralMiddleware, :BarMiddle, :FooMiddle, :BazMiddle, :PazMiddle
        it "should allow me to add middleware before other middleware" do
          @konstant.use(GeneralMiddleware)
          @konstant.stack(:bar).use(BarMiddle)
          @konstant.stack(:foo, :before => :bar).use(FooMiddle)
          result = @konstant.middlewares.map{|m| m.middleware}
          result.should == [GeneralMiddleware, FooMiddle, BarMiddle]
        end
        
        it "should allow me to add middleware after other middleware " do
          @konstant.use(BarMiddle)
          @konstant.stack(:general).use(GeneralMiddleware)
          @konstant.stack(:foo, :after => BarMiddle).use(FooMiddle)
          result = @konstant.middlewares.map{|m| m.middleware}
          result.should == [ BarMiddle, FooMiddle, GeneralMiddleware]
        end
        
        it "should allow me to add middleware arbitrarily and have it in the correct order" do
          @konstant.use(GeneralMiddleware)
          @konstant.stack(:bar).use(BarMiddle)
          @konstant.stack(:foo, :before => :bar).use(FooMiddle)
          @konstant.stack(:baz, :after  => :foo).use(BazMiddle)
          @konstant.stack(:paz, :before => GeneralMiddleware).use(PazMiddle)
          result = @konstant.middlewares.map{|m| m.middleware}
          result.should == [PazMiddle, GeneralMiddleware, FooMiddle, BazMiddle, BarMiddle]
        end
      end
    end
    
    describe "Pancake Middleware Construction" do
      before(:each) do
        @konstant = Pancake
      end
      
      it_should_behave_like("Stack Middleware Enabled Constant")
    end
    
    describe "Pancake Stack Middleware" do
      before(:each) do
        @konstant = Pancake::Stack
      end
      it_should_behave_like("Stack Middleware Enabled Constant")
    end
    
    describe "An inherited panckae stack app" do
      before(:each) do
        class ::FooApp < Pancake::Stack; end
        @konstant = FooApp
      end
      it_should_behave_like("Stack Middleware Enabled Constant")
    end
    
    describe "a deeply inherited stack app" do
      before(:each) do
        class ::FooApp < Pancake::Stack; end
        class ::BarApp < FooApp; end
        @konstant = BarApp
      end
      it_should_behave_like("Stack Middleware Enabled Constant")
    end
      
    it "should allow me to inherit middleware from a parent stack" do
      class ::FooApp < Pancake::Stack; end
      FooApp.use(GeneralMiddleware)
      class ::BarApp < FooApp; end
      BarApp.stack(:foo).use(FooMiddle)
      BarApp.stack(:bar, :after => GeneralMiddleware).use(BarMiddle)
      result = BarApp.middlewares.map{|m|m.middleware}
      result.should == [GeneralMiddleware, BarMiddle, FooMiddle]
    end
    
  end # Stack Inheritance
end