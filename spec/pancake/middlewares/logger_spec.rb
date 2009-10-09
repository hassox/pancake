require File.dirname(__FILE__) + '/../../spec_helper'

describe Pancake::Middlewares::Logger do
  before do
    Pancake.stack(:logger).use(Pancake::Middlewares::Logger)
    class ::PancakeSpecLogger
      def self.call(env)
        Rack::Response.new("OK").finish
      end
    end
  end

  after do
    clear_constants :PancakeSpecLogger
    FileUtils.rm_rf(File.join(Pancake.get_root(__FILE__), "log"))
  end

  def app
    Pancake.start(:root => Pancake.get_root(__FILE__)){ PancakeSpecLogger }
  end

  it "should inject a logger into the request env" do
    the_app = app
    env = Rack::MockRequest.env_for("/")
    env['rack.logger'].should be_nil
    the_app.call(env)
    env['rack.logger'].class.should == Pancake::Logger
  end
end
