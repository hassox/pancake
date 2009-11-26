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

  describe "handle errors" do
    before do
      @orig_env = ENV['RACK_ENV']
    end

    after do
      ENV['RACK_ENV'] = @orig_env
    end

    it "should allow me to set the error handling status to true" do
      Pancake.handle_errors!(true)
      Pancake.handle_errors?.should be_true
    end

    it "should allow me to set the error handling status to a false" do
      Pancake.handle_errors!(false)
      Pancake.handle_errors?.should be_false
    end

    it "should allow me to set the error handling status to a value" do
      Pancake.handle_errors!("some_string")
      ENV['RACK_ENV'] = "some_string"
      Pancake.handle_errors?.should be_true
      ENV['RACK_ENV'] = "other string"
      Pancake.handle_errors?.should be_false
    end

    it "should allow me to set the error handling status to an array of strings" do
      Pancake.handle_errors!("some", "another")
      ENV['RACK_ENV'] = "some"
      Pancake.handle_errors?.should be_true
      ENV['RACK_ENV'] = "another"
      Pancake.handle_errors?.should be_true
      ENV['RACK_ENV'] = "different"
      Pancake.handle_errors?.should be_false
    end

    it "should default to handling errors in production" do
      Pancake.default_error_handling!
      ENV['RACK_ENV'] = "production"
      Pancake.handle_errors?.should be_true
    end

    it "should default to not handling errors in development" do
      Pancake.default_error_handling!
      ENV['RACK_ENV'] = "development"
      Pancake.default_error_handling!
    end

    it "should default to handling errors in test" do
      Pancake.default_error_handling!
      ENV['RACK_ENV'] = "test"
      Pancake.default_error_handling!
    end
  end

  describe "master stack" do
    before(:all) do
      @b4 = Pancake.master_stack
    end

    after(:all) do
      Pancake.master_stack = @b4
    end

    it "should have a master stack" do
      Pancake.should respond_to(:master_stack)
    end

    it "should let me set a master stack" do
      mock_stack = mock("stack", :null_object => true)
      Pancake.master_stack = mock_stack
      Pancake.master_stack.should == mock_stack
    end
  end
end
