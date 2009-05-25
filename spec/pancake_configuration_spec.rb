require File.dirname(__FILE__) + '/spec_helper'

describe "pancake configuartion" do

  it "should provide access to it's configuration object" do
    Pancake.configuration.class.should inherit_from(Pancake::Configuration::Base)
  end
    
end