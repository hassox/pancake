require 'spec_helper'

describe Pancake::Mixins::StackHelper do
  before do
    class ::FooStack < Pancake::Stack
      class Bar
        include Pancake::Mixins::StackHelper
      end
    end
  end

  after do
    clear_constants :FooStack, :BarStack, :FooBar
  end

  it "should provide access to the stack helper to the Bar class" do
    FooStack::Bar.stack_class.should == FooStack
  end

  it "should track the class for a newly namespaced stack" do
    class ::BarStack < FooStack
      class Bar < ::FooStack::Bar
      end
    end

    BarStack::Bar.stack_class.should == BarStack
  end

  it "should raise an exception when including it into a class that is not of a stack" do
    lambda do
      class ::FooBar
        include Pancake::Mixins::StackHelper
      end
    end.should raise_error
  end

  it "should remember the stack it was initially mixed into if it's inherited to a non namespaced class" do
    class ::FooBar < FooStack::Bar; end
    FooBar.stack_class.should == FooStack
  end

  it "should provide access to the stack helper from an instance of the Bar class" do
    FooStack::Bar.new.stack_class.should == FooStack
  end

end
