require 'spec_helper'

describe Pancake::Constants do
  it "should have the ENV_LOGGER_KEY constant" do
    Pancake::Constants::ENV_LOGGER_KEY.should == "rack.logger"
  end
end
