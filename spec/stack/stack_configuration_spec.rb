require File.dirname(__FILE__) + '/../spec_helper'

describe "pancake stack configuration" do
  
  before(:each) do
    class ::FooStack < Pancake::Stack
    end
  end
  
  after(:each) do
    clear_constants(:FooStack)
  end
  
  it "should provide access to the stack configuration" do
    FooStack.configuration.class.should inherit_from(Pancake::Configuration::Base)
  end
  
  it "should allow me to set defaults on a stack" do
    FooStack.configuration do 
      default :foo, :bar
      default :bar, "Foo Bar Man"
    end
    FooStack.configuration.foo.should == :bar
    FooStack.configuration.bar.should == "Foo Bar Man"
  end

  it "should provide access to the roots of the stack through the config object" do
    FooStack.roots << Pancake.get_root(__FILE__)
    FooStack.roots.should == [Pancake.get_root(__FILE__)]
    FooStack.configuration.roots.should == [Pancake.get_root(__FILE__)]
  end
  
  it "should allow me to extend the configuration" do
    class Pancake::Stack::Configuration
      default :foo, :bar, "I am a foo default"
      default :bar do
        foobar
      end
      
      def foobar
        :foobar
      end
    end
    class FooBarStack < Pancake::Stack; end
    
    FooBarStack.configuration.foo.should == :bar
    FooBarStack.configuration.bar.should == :foobar
  end 

end