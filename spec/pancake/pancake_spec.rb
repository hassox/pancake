require File.dirname(__FILE__) + '/../spec_helper'

describe "pancake" do

  it "should get the correct root directory for a file" do
    Pancake.get_root(__FILE__).should == File.expand_path(File.dirname(__FILE__))
  end

  it "should join the arguments together to form a path" do
    Pancake.get_root(__FILE__, "foo").should == File.expand_path(File.join(File.dirname(__FILE__), "foo"))
  end

  describe "stack labels" do
    before(:each) do
      @orig_lables = Pancake.stack_labels
    end

    after(:each) do
      Pancake.stack_labels = @orig_labels
    end

    it "should allow me to set a stack type on panckae" do
      Pancake.stack_labels = [:foo, :bar]
      Pancake.stack_labels.should == [:foo, :bar]
    end

    it "should provide me with stack label of [:production] by default" do
      Pancake.stack_labels = nil
      Pancake.stack_labels.should == [:production]
      Pancake.stack_labels = []
      Pancake.stack_labels.should == [:production]
    end
  end

end
