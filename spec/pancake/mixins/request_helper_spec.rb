require File.dirname(__FILE__) + '/../../spec_helper'

describe Pancake::Mixins::RequestHelper do
  before do
    class ::FooBar
      include Pancake::Mixins::RequestHelper
    end
  end

  after do
    clear_constants :FooBar
  end

  describe "logger" do
    before do
      @logger = mock("logger")
      @app = FooBar.new
      @app.env = {Pancake::Constants::ENV_LOGGER_KEY => @logger}
    end

    it "should access the rack.logger variable when using" do
      @logger.should_receive(:foo)
      @app.logger.foo
    end
  end

  describe "v" do
    it "should store the data put into v into the env" do
      env = {}
      foo = FooBar.new
      foo.env = env
      foo.v[:data] = :some_data
      env[Pancake::Mixins::RequestHelper::VAULT_KEY][:data].should == :some_data
    end
  end
end
