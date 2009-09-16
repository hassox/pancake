require File.dirname(__FILE__) + '/../../../spec_helper'

describe Pancake::Stacks::Short do
  
  before do
    $captures = []
    class ::ShortMiddle
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
      use ShortMiddle

      get "/foo" do
        "HERE"
      end
    end
  end
  
  after do 
    clear_constants :ShortFoo, :ShortMiddle
  end

  def app
    ShortFoo.stackup
  end
  
  it "should go through the middleware to get to the actions" do
    get "/foo"
    $captures.should == [ShortMiddle]
  end
end
