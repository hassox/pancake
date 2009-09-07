module Pancake
  module RequestHelper
    def url(name, opts = {})
      konfig = request.env[Pancake::Router::CONFIGURATION_KEY]
      konfig.router.generate(name, opts)
    end

    def url_for(app_name, name_or_opts, opts = {})
      if konfig = Pancake.configuration.configs[app_name]
        konfig.router.generate(name_or_opts, opts)
      else
        raise Pancake::Errors::UnknownConfiguration
      end
    end
    
    def request
      @request ||= Rack::Request.new(env)
    end
    
  end # RequestHelper
end # Pancake
