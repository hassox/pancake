require File.dirname(__FILE__) + '/../spec_helper'

describe "Pancake::Stack inheritance" do
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
    Pancake::Stack.on_inherit do |base|
      $collector << base
    end
    
    class ::FooStack < Pancake::Stack
    end
    
    $collector.should == [FooStack]
  end
  
  it "should be able to add multiple inheritance hooks" do
    Pancake::Stack.on_inherit{|b| $collector << b}
    Pancake::Stack.on_inherit{|b| $collector << :foo}
    
    class ::FooStack < Pancake::Stack
    end
    
    $collector.should == [FooStack, :foo]
  end
end