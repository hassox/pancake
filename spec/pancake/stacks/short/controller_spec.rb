require File.dirname(__FILE__) + '/../../../spec_helper'

describe Pancake::Stacks::Short::Controller do
  
  before do
    class ::ShortFoo < Pancake::Stacks::Short
      class Controller
        def do_dispatch!
          dispatch!
        end
        
        publish
        def show;   "show";    end
        
        publish
        def index;  "index";   end
        
        protected
        def a_protected_method; "protected"; end
        
        private
        def a_private_method; "private"; end
      end
    end
    ShortFoo.roots << Pancake.get_root(__FILE__)
  end
  
  after do 
    clear_constants "ShortFoo"
  end

  def app
    ShortFoo.stackup
  end

  it "should have a Controller" do 
    Pancake::Stacks::Short.constants.map(&:to_s).should include("Controller")
  end
  
  it "should inherit the subclass controller from the parent controller" do
    ShortFoo::Controller.should inherit_from(Pancake::Stacks::Short::Controller)
  end
  
  describe "dispatching an action" do
    before do
      @controller = ShortFoo::Controller.new(env_for)
    end
    
    it "should call the 'show' action" do
      @controller.params[:action] = "show"
      result = @controller.do_dispatch!
      result[0].should == 200
      result[2].body.to_s.should  == "show"
    end
    
    it "should dispatch to the index action by default" do
      @controller.params[:action] = nil
      result = @controller.do_dispatch!
      result[0].should == 200
      result[2].body.to_s.should == "index"
    end

    it "should raise a Pancake::Response::NotFound exception when an action is now found" do
      @controller.params[:action] = :does_not_exist
      lambda do
        @controller.do_dispatch!
      end.should raise_error(Pancake::Errors::NotFound)
    end
    
    it "should not dispatch to a protected method" do
      @controller.params[:action] = "a_protected_method"
      lambda do
        @controller.do_dispatch!
      end.should raise_error(Pancake::Errors::NotFound)
    end
    
    it "should not dispatch to a private method" do
      @controller.params[:action] = "a_private_method"
      lambda do
        @controller.do_dispatch!
      end.should raise_error(Pancake::Errors::NotFound)
    end
    
    describe "helper in methods" do
      before do
        module PancakeTestHelper
          def some_helper_method
            "foo"
          end
        end
        
        class ShortFoo
          class Controller
            include PancakeTestHelper
          end
        end
      end
      after do
        clear_constants "PancakeTestHelper"
      end
      
      it "should not call a helper method" do
        @controller.params[:action] = "some_helper_method"
        lambda do
          result = @controller.do_dispatch!
        end.should raise_error(Pancake::Errors::NotFound)
      end
      
    end
  end
end