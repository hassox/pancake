require File.dirname(__FILE__) + '/spec_helper'

describe "pancake" do
  
  it "should get the correct root directory for a file" do
    Pancake.get_root(__FILE__).should == File.expand_path(File.dirname(__FILE__))
  end
end