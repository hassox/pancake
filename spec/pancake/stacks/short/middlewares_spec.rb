require File.dirname(__FILE__) + '/../../../spec_helper'

describe "short stack middleware" do
  before do
    class ::FooBar < Pancake::Stacks::Short
      add_root(__FILE__)
    end
  end

  after do
    clear_constants :FooBar
  end

  it "should include the Pancake::Middlewares::Static middleware" do
    FooBar.stackup
    middleware = FooBar.middlewares.detect do |m|
      m.middleware == Pancake::Middlewares::Static
    end
    middleware.should_not be_nil
    middleware.args.should == [FooBar]
  end
end
