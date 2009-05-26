require File.dirname(__FILE__) + '/../spec_helper'

describe "Pancake::Stack inheritance" do
  describe "inheritance hooks" do
    before(:all) do
      $on_inherit_blocks = Pancake::Stack.on_inherit.dup
    end
    after(:all) do
      Pancake::Stack.on_inherit.clear
      $on_inherit_blocks.each do |blk|
        Pancake::Stack.on_inherit(&blk)
      end
    end
  
    before(:each) do
      $collector = []
      Pancake::Stack.on_inherit.clear
    end
  
    after(:each) do
      clear_constants(:FooStack)
    end
  
    it "should be able to add inheritance hooks" do
      Pancake::Stack.on_inherit do |base, parent|
        $collector << base
      end
    
      class ::FooStack < Pancake::Stack
      end
    
      $collector.should == [FooStack]
    end
  
    it "should be able to add multiple inheritance hooks" do
      Pancake::Stack.on_inherit{|b,p| $collector << b}
      Pancake::Stack.on_inherit{|b,p| $collector << :foo}
    
      class ::FooStack < Pancake::Stack
      end
    
      $collector.should == [FooStack, :foo]
    end
  end
  
  describe "Inheriting Stacks" do
    before(:all) do 
      clear_constants(:FooStack, :BarStack)
    end
    
    before(:each) do
      class ::FooStack < Pancake::Stack; end
    end
    
    after(:each) do
      clear_constants(:FooStack, :BarStack)
    end
    
    it "should allow us to inherit a stack" do
      class ::BarStack < ::FooStack; end
      BarStack.configuration.should_not == FooStack.configuration
      BarStack.roots.object_id.should_not == FooStack.roots.object_id
    end
    
    it "should not inherit the router" do
      class ::BarStack < ::FooStack; end
      BarStack::Router.should_not == FooStack::Router
    end
    
    
  end
end