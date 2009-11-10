require File.dirname(__FILE__) + '/../../../spec_helper'

describe Pancake::Stacks::Short do

  before do
    $captures = []
    class ::ShortMiddle
      attr_accessor :app
      def initialize(app)
        @app = app
      end

      def call(env)
        $captures << ShortMiddle
        @app.call(env)
      end
    end

    class ::ShortFoo < Pancake::Stacks::Short
      roots << Pancake.get_root(__FILE__)
      add_root(__FILE__, "..", "..", "fixtures", "stacks", "short", "foobar")
      add_root(__FILE__, "..", "..", "fixtures", "stacks", "short", "foobar", "other_root")
      use ShortMiddle


      get "/foo" do
        "HERE"
      end

      get "/" do
        $captures << self.class
        render :inherited_from_base
      end
    end

    @app = ShortFoo
  end

  after do
    clear_constants :ShortFoo, :ShortMiddle, :OtherFoo, "ShortFoo::Router"
  end

  def app
    @app.stackup
  end

  it "should go through the middleware to get to the actions" do
    get "/foo"
    $captures.should == [ShortMiddle]
  end

  describe "inheritance" do
    before do
      class ::OtherFoo < ShortFoo; end
      ShortFoo.router.mount(OtherFoo, "/other")
    end

    it "should render the same template in the child as it does in the parent" do
      get "/"
      $captures.pop.should == ShortFoo::Controller
      last_response.should match(/inherited from base/)
      result = get "/other/"
      $captures.pop.should == OtherFoo::Controller
      last_response.should match(/inherited from base/)
    end
  end

  describe "helpers" do
    before do
      $captures = []
      class ::ShortFoo
        helpers do
          def in_helper?
            $captures << :in_helper?
          end
        end
      end
    end

    it "should allow me to setup a helper method in the stack" do
      ShortFoo.get("/with_helper"){ in_helper?; "OK" }
      result = get "/with_helper"
      result.should be_successful
      $captures.should include(:in_helper?)
    end

    it "should provide the helpers in child stacks" do
      class ::OtherFoo < ShortFoo; end
      OtherFoo.get("/helper_action"){ in_helper?; "OK" }
      @app = OtherFoo
      result = get "/helper_action"
      result.should be_successful
      $captures.should include(:in_helper?)
    end

    it "should let me mixin modules to the helpers" do
      module ::OtherFoo
        def other_helper
          $captures << :other_helper
        end
      end
      ShortFoo.helpers{ include OtherFoo }
      ShortFoo.get("/foo"){ other_helper; "OK" }
      result = get "/foo"
      result.should be_successful
      $captures.should include(:other_helper)
    end
  end
end
