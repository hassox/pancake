require File.dirname(__FILE__) + '/../spec_helper'

describe "Pancake::Stack inheritance" do
  before(:each) do
    $collector = []
    clear_constants("FooStack")
    Pancake::Stack.on_inherit.clear
  end
  
  it "should be able to add inheritance hooks" do
    Pancake::Stack.on_inherit do |base|
      $collector << base
    end
    
    class FooStack < Pancake::Stack
    end
    
    $collector.should == [FooStack]
  end
  
  it "should be able to add multiple inheritance hooks" do
    Pancake::Stack.on_inherit{|b| $collector << b}
    Pancake::Stack.on_inherit{|b| $collector << :foo}
    
    class FooStack < Pancake::Stack
    end
    
    $collector.should == [FooStack, :foo]
  end
end