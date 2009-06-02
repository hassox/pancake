require File.dirname(__FILE__) + '/../spec_helper'

describe "Pancake::Stack.new_app_instance" do
  
  before(:each) do
    class ::FooStack < Pancake::Stack
      
    end
  end
  
  after(:each) do
    clear_constants(:FooStack)
  end
  
  it "should provide a new instance of the applciation" do
    FooStack.new_app_instance.should == Pancake::MISSING_APP
  end
  
  it "should allow me to overwrite the new_app_instance for this stack" do
    class ::BarStack < Pancake::Stack
      def self.new_app_instance
        ::Pancake::OK_APP
      end
    end
    
    BarStack.new_app_instance.should == ::Pancake::OK_APP
  end
end