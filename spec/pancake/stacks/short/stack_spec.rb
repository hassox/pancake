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
  end

  after do
    clear_constants :ShortFoo, :ShortMiddle, :OtherFoo, "ShortFoo::Router"
  end

  def app
    ShortFoo.stackup
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
end
