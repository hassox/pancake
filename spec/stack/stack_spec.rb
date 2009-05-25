require File.dirname(__FILE__) + '/../spec_helper'

describe "Pancake::Stack" do
  before(:each) do
    clear_constants("FooStack")
    
    class FooStack < Pancake::Stack
    end
  end
  
  describe "roots" do
    it "should provide access to setting the roots" do
      FooStack.roots.should be_empty
      FooStack.roots << File.expand_path(File.dirname(__FILE__))
      FooStack.roots.should include(File.expand_path(File.dirname(__FILE__)))
    end
  
    it "should provide access to adding a root" do
      FooStack.roots.should be_empty
      FooStack.roots << Pancake.get_root(__FILE__)
      FooStack.roots.should include(File.expand_path(File.dirname(__FILE__)))
    end
  
    it "should allow me to get multiple roots in the order they're added" do
      FooStack.roots.should be_empty
      FooStack.roots << Pancake.get_root(__FILE__)
      FooStack.roots << "/tmp"
      FooStack.roots.should == [Pancake.get_root(__FILE__), "/tmp"]
    end
  
    it "should iterate over the roots in the direction they're added" do
      FooStack.roots.should be_empty
      FooStack.roots << Pancake.get_root(__FILE__)
      FooStack.roots << "/tmp"
      FooStack.roots.map{|f| f}.should == [Pancake.get_root(__FILE__), "/tmp"]
    end
  end # roots
  
  describe "initialize stack" do
    it "should mark a stack as initialized once it has called the initialize_stack method" do
      FooStack.roots << Pancake.get_root(__FILE__)
      FooStack.initialize_stack
      FooStack.should be_initialized
    end
    
    it "should not be initialized when it has not called initialize_stack" do
      FooStack.should_not be_initialized
    end    
  end
end