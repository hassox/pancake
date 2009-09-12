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
    clear_constants "ShortFoo", :ShortBar
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
      @controller.params["action"] = "show"
      result = @controller.do_dispatch!
      result[0].should == 200
      result[2].body.join.should  == "show"
    end
    
    it "should dispatch to the index action by default" do
      @controller.params["action"] = nil
      result = @controller.do_dispatch!
      result[0].should == 200
      result[2].body.join.should == "index"
    end

    it "should raise a Pancake::Response::NotFound exception when an action is now found" do
      @controller.params["action"] = :does_not_exist
      lambda do
        @controller.do_dispatch!
      end.should raise_error(Pancake::Errors::NotFound)
    end
    
    it "should not dispatch to a protected method" do
      @controller.params["action"] = "a_protected_method"
      lambda do
        @controller.do_dispatch!
      end.should raise_error(Pancake::Errors::NotFound)
    end
    
    it "should not dispatch to a private method" do
      @controller.params["action"] = "a_private_method"
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
        @controller.params["action"] = "some_helper_method"
        lambda do
          result = @controller.do_dispatch!
        end.should raise_error(Pancake::Errors::NotFound)
      end
      
    end
  end

  describe "accept type negotiations" do
    before do
      class ::ShortBar < Pancake::Stacks::Short
        roots << Pancake.get_root(__FILE__)
        # makes the dispatch method public
        def do_dispatch!
          dispatch!
        end

        provides :json, :xml

        get "/foo/bar(.:format)" do
          "format #{content_type.inspect}"
        end
      end # ShortBar
    end # before

    def app
      ShortBar.stackup
    end
    
    it "should get json by default" do
      result = get "/foo/bar", {}, "HTTP_ACCEPT" => "application/json"
      result.status.should == 200
      result.headers["Content-Type"].should == "application/json"
      result.body.to_s.should == "format :json"
    end
    
    it "should get xml when specified" do
      result = get "/foo/bar.xml"
      result.status.should == 200
      result.headers["Content-Type"].should == "application/xml"
      result.body.to_s.should == "format :xml"
    end

    it "should get json when specified with */*" do
      result = get "/foo/bar", {}, "HTTP_ACCEPT" => "*/*"
      result.status.should == 200
      result.body.to_s.should == "format :json"
      result.headers["Content-Type"].should == "application/json"
    end

    it "should get xml when specified with */* and application/xml" do
      result = get "/foo/bar", {}, "HTTP_ACCEPT" => "application/xml,*/*"
      result.status.should == 200
      result.body.to_s.should == "format :xml"
      result.headers["Content-Type"].should == "application/xml"
    end

    it "should use the format in preference to the content type" do
      result = get "/foo/bar.xml", {}, "HTTP_ACCEPT" => "*/*"
      result.status.should == 200
      result.body.to_s.should == "format :xml"
      result.headers["Content-Type"].should == "application/xml"
    end
  end # Accept type negotiations
end
