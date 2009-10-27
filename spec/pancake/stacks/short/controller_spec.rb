require File.join(File.expand_path(File.dirname(__FILE__)),'..', '..', '..', 'spec_helper')

describe Pancake::Stacks::Short::Controller do

  before do
    class ::ShortFoo < Pancake::Stacks::Short
      add_root(__FILE__)
      add_root(File.expand_path(File.dirname(__FILE__)), "..", "fixtures", "stacks", "short", "foobar")
      class Controller
        def do_dispatch!
          dispatch!
        end

        publish
        def show;   "show";    end

        publish
        def index;  "index";   end

        publish
        def a_rack_response
          r = Rack::Response.new
          r.redirect("/foo")
          r
        end

        publish
        def an_array_response
          [200, {"Content-Type" => "text/plain"}, ["Custom Array Response"]]
        end

        protected
        def a_protected_method; "protected"; end

        private
        def a_private_method; "private"; end
      end
    end
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

    it "should raise a Pancake::Response::NotFound exception when an action is now found" do
      @controller.params["action"] = :does_not_exist
      result = @controller.do_dispatch!
      result[0].should == 404
    end

    it "should not dispatch to a protected method" do
      @controller.params["action"] = "a_protected_method"
      result = @controller.do_dispatch!
      result[0].should == 404
    end

    it "should not dispatch to a private method" do
      @controller.params["action"] = "a_private_method"
      result = @controller.do_dispatch!
      result[0].should == 404
    end

    it "should raise an exception if pancake has told it not to handle errors" do
      Pancake.should_receive(:handle_errors?).and_return(false)
      @controller.params["action"] = "a_private_method"
      lambda do
        @controller.do_dispatch!
      end.should raise_error
    end

    it "should let me return an array as a rack response" do
      @controller.params["action"] = "an_array_response"
      result = @controller.do_dispatch!
      result.should == [200, {"Content-Type" => "text/plain"}, ["Custom Array Response"]]
    end

    it "should allow me to return a Rack::Response" do
      @controller.params["action"] = "a_rack_response"
      result = @controller.do_dispatch!
      result[0].should == 302
      result[1]["Location"].should == "/foo"
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
        result = @controller.do_dispatch!
        result[0].should == 404
      end

    end
  end

  describe "request helper methods" do
    before do
      class ::RequestFoo < Pancake::Stacks::Short
        add_root(__FILE__, "..", "..", "fixtures", "stacks", "short", "foobar")
        get "/foobar", :_name => :foobar do
          url(:foobar)
        end

        get "/template", :_name => :template do
          render :template
        end

        get "/vault" do
          v[:my_data] = "some data"
          render :vault
        end
      end
    end

    after do
      clear_constants :RequestFoo
    end

    def app
      RequestFoo.stackup
    end

    it "should include the request helper methods" do
      (Pancake::Mixins::RequestHelper > ShortFoo::Controller).should be_true
    end

    it "should provide access to the request methods in the controller" do
      result = get "/foobar"
      result.body.should == "/foobar"
    end

    it "should provide access to the helper methods in the views" do
      result = get "/template"
      result.status.should == 200
      result.body.should include("/foobar")
      result.body.should include("In Template")
    end

    it "should allow me to get information between the view and the controller" do
      result = get "/vault"
      result.status.should == 200
      result.body.should include("some data")
      result.body.should include("In Vault")
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

        provides :json, :xml, :text

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

    it "should get the default when specified with */*" do
      result = get "/foo/bar", {}, "HTTP_ACCEPT" => "application/xml,*/*"
      result.status.should == 200
      result.body.to_s.should == "format :json"
      result.headers["Content-Type"].should == "application/json"
    end

    it "should use the format in preference to the content type" do
      result = get "/foo/bar.xml", {}, "HTTP_ACCEPT" => "*/*"
      result.status.should == 200
      result.body.to_s.should == "format :xml"
      result.headers["Content-Type"].should == "application/xml"
    end

    it "should get json by default" do
      result = get "/foo/bar"
      result.status.should == 200
      result.body.to_s.should == "format :json"
      result.headers["Content-Type"].should == "application/json"
    end

    it "should correctly negotiate different scenarios" do
      r = get "/foo/bar", {}, {}
      r.body.should == "format :json"
      r = get "/foo/bar.xml", {}, {}
      r.body.should == "format :xml"
      r = get "/foo/bar", {}, {}
      r.body.should == "format :json"
      r = get "/foo/bar", {}, "HTTP_ACCEPT" => "application/xml"
      r.body.should == "format :xml"
      r = get "/foo/bar.json"
      r.body.should == "format :json"
    end

    it "should negotiate based on extension" do
      r = get "/foo/bar"
      r.body.should == "format :json"
      r = get "/foo/bar.text"
      r.body.should == "format :text"
      r = get "/foo/bar.xml"
      r.body.should == "format :xml"
      r = get "/foo/bar.txt"
      r.body.should == "format :text"
    end

    it "should not provide a response to a format that is not provided" do
      r = get "/foo/bar.svg"
      r.status.should == 406
    end
  end # Accept type negotiations

  describe "error handling" do
    before do
      class ::ShortFoo
        provides :html, :xml

        get "/foo(.:format)" do
          "HERE"
        end

        get "/bad" do
          raise "This is bad"
        end

        get "/template/:name" do
          render params[:name]
        end

      end
    end

    describe "default error handling" do
      def app
        ShortFoo.stackup
      end

      it "should handle a NotFound  by default" do
        result = get "/does_not_exist"
        result.status.should == 404
        result.body.should include(Pancake::Errors::NotFound.description)
      end

      it "should return a 500 status for a Random Error by wrapping it in a Pancake::Errors::Server" do
        result = get "/bad"
        result.status.should == 500
        result.body.should include(Pancake::Errors::Server.description)
      end

      it "should handle a NotAcceptable error" do
        result = get "/foo.no_format_i_know_of"
        result.status.should == 406
        result.body.should include(Pancake::Errors::NotAcceptable.description)
      end

      it "should return 406 for a format that is in pancake but not in the group" do
        r = get "/foo.svg"
        r.status.should == 406
      end
    end

    describe "custom error handling" do
      before do
        ShortFoo.handle_exception do |error|
          out = ""
          out << "CUSTOM "
          out << error.name
          out << ": "
          out << error.description
        end

        ShortFoo.get "/bad" do
          raise "Really Bad"
        end
      end

      after do
        ShortFoo.handle_exception(&Pancake::Stacks::Short::Controller::DEFAULT_EXCEPTION_HANDLER)
      end

      it "should handle Pancake::Errors::NotFound errors" do
        r = get "/not_a_thing"
        r.status.should == 404
        r.body.should include("CUSTOM")
        r.body.should include(Pancake::Errors::NotFound.description)
      end

      it "should handle an unknown server error" do
        r = get "/bad"
        r.status.should == 500
        r.body.should include("CUSTOM")
        r.body.should include(Pancake::Errors::Server.description)
      end

      it "should let me do stuff on an instance level inside the handle exception" do
        ShortFoo.handle_exception do |error|
          self.status = 123
          "BOOO!"
        end

        r = get "/bad"
        r.status.should == 123
        r.body.should == "BOOO!"
      end

    end

    describe "rendering" do

      it "should render a template" do
        result = get "/template/basic"
        result.body.should include("basic template")
      end

      it "should inherit from a base view provided by short stacks" do
        File.file?(File.join(File.expand_path(File.dirname(__FILE__)), "..", "fixtures", "stacks", "short", "foobar", "views", "base.html.haml")).should be_false
        result = get "/template/inherited_from_base"
        result.body.should include("inherited from base")
        result.body.should include("Pancake")
      end

      it "should allow me to overwrite the base tempalte in later roots" do
        ShortFoo.add_root(File.expand_path(File.dirname(__FILE__)), "..", "fixtures", "stacks", "short", "foobar", "other_root")
        result = get "/template/inherited_from_base"
        result.body.should include("inherited from base")
        result.body.should include("Not the default pancake")
      end
    end
  end
end
