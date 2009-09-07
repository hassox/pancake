module Pancake
  module RequestHelper
    def url(name, opts = {})
      konfig = request.env[Pancake::Router::CONFIGURATION_KEY]
      konfig.router.generate(name, opts)
    end

    def request
      @request ||= Rack::Request.new(env)
    end
    
  end # RequestHelper
end # Pancake
