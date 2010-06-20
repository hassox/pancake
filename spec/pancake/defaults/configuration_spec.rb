require 'spec_helper'

describe "Pancake configuration defaults" do
  describe "logging defaults" do
    before do
      Pancake.root = Pancake.get_root(__FILE__)
    end

    after do
      Pancake.reset_configuration
      FileUtils.rm_rf(File.join(Pancake.root, "log"))
    end

    it "should set the log path" do
      path = Pancake.configuration.log_path
      path.should == "log/pancake_#{Pancake.env}.log"
    end

    it "should set the log level to :info" do
      Pancake.configuration.log_level.should == :info
    end

    it "should set the delimiter to ~ " do
      Pancake.configuration.log_delimiter.should == " ~ "
    end

    it "should set auto flush to true" do
      Pancake.configuration.log_auto_flush.should be_true
    end

    it "should set log to file to false" do
      Pancake.configuration.log_to_file.should be_false
    end

    it "should set log to file to true if env is production" do
      Pancake.stub(:env).and_return("production")
      Pancake.configuration.log_to_file.should be_true
    end

    it "should set the log_stream to STDOUT by default" do
      Pancake.configuration.log_stream.should === STDOUT
    end

    it "should set the log stream to a file path when told to log to file" do
      Pancake.configuration.log_to_file = true
      result = Pancake.configuration.log_path
      result.should match(/\log\/pancake_#{Pancake.env}\.log$/)
    end

    it "should create the directory if it doesn't exist" do
      File.exists?(File.join(Pancake.root, "log")).should be_false
      Pancake.configuration.log_to_file = true
      Pancake.configuration.log_stream
      File.exists?(File.join(Pancake.root, "log")).should be_true
    end
  end

end
