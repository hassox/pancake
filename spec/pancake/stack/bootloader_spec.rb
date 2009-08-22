require File.dirname(__FILE__) + '/../../spec_helper'

describe "Stack BootLoaders" do
  
  before(:each) do
    clear_constants(:FooStack, :BarStack)
  end
  
  it "should inherit the standard bootloaders from Pancake::Stack" do
    class ::FooStack < Pancake::Stack; end
    FooStack::BootLoader.should inherit_from(Pancake::Stack::BootLoader)
  end
  
  it "should get all the bootloaders from pancake stack" do
    class ::FooStack < Pancake::Stack; end
    FooStack::BootLoader.map{|n,bl|n}.should == Pancake::Stack::BootLoader.map{|n,bl|n}
  end
  
  it "should let FooStack define it's own bootloaders" do
    class ::FooStack < Pancake::Stack; end
    FooStack::BootLoader.add(:foo_stack_bootloader){ def run!; end }
    FooStack::BootLoader.map{|n,b|n}.should include(:foo_stack_bootloader)
    Pancake::Stack::BootLoader.map{|n,b|n}.should_not include(:foo_stack_bootloader)
  end
  
  it "should not pollute other bootloaders" do
    class ::FooStack < Pancake::Stack; end
    FooStack::BootLoader.add(:foo_stack_bootloader){ def run!; end }
    class ::BarStack < Pancake::Stack; end
    FooStack::BootLoader.map{|n,b|n}.should_not == BarStack::BootLoader.map{|n,b|n}
    BarStack::BootLoader.map{|n,b|n}.should_not include(:foo_stack_bootloader)
  end
  
  it "should inherit custom bootloaders" do
    class ::FooStack < Pancake::Stack; end
    FooStack::BootLoader.add(:foo_stack_bootloader){ def run!; end }
    class ::BarStack < FooStack; end
    BarStack::BootLoader.map{|n,b|n}.should include(:foo_stack_bootloader)
  end

end