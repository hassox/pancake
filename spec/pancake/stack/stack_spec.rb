require File.dirname(__FILE__) + '/../../spec_helper'

describe "Pancake::Stack" do
  before(:each) do
    class ::StackSpecStack < Pancake::Stack
    end
  end

  after(:each) do
    clear_constants(:StackSpecStack)
  end

  describe "roots" do

    it "should provide access to setting the roots" do
      StackSpecStack.roots.should be_empty
      StackSpecStack.roots << File.expand_path(File.dirname(__FILE__))
      StackSpecStack.roots.should include(File.expand_path(File.dirname(__FILE__)))
    end

    it "should provide access to adding a root" do
      StackSpecStack.roots.should be_empty
      StackSpecStack.roots << Pancake.get_root(__FILE__)
      StackSpecStack.roots.should include(File.expand_path(File.dirname(__FILE__)))
    end

    it "should allow me to get multiple roots in the order they're added" do
      StackSpecStack.roots.should be_empty
      StackSpecStack.roots << Pancake.get_root(__FILE__)
      StackSpecStack.roots << "/tmp"
      StackSpecStack.roots.should == [Pancake.get_root(__FILE__), "/tmp"]
    end

    it "should iterate over the roots in the direction they're added" do
      StackSpecStack.roots.should be_empty
      StackSpecStack.roots << Pancake.get_root(__FILE__)
      StackSpecStack.roots << "/foo"
      StackSpecStack.roots.map{|f| f}.should == [Pancake.get_root(__FILE__), "/foo"]
    end

    it "should allow me to set a root with a file" do
      StackSpecStack.add_root(__FILE__)
      StackSpecStack.roots.should include(Pancake.get_root(__FILE__))
    end
  end # roots

  # describe "initialize stack" do

    it "should mark a stack as initialized once it has called the initialize_stack method" do
      StackSpecStack::BootLoader
      StackSpecStack.roots << ::Pancake.get_root(__FILE__)
      StackSpecStack.initialize_stack
      StackSpecStack.should be_initialized
    end

    it "should not be initialized when it has not called initialize_stack" do
      StackSpecStack.should_not be_initialized
    end
  # end
end
