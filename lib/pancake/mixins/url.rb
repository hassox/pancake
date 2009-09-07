module Pancake
  module Url
    module Generation
      def url(name, opts = {})
        konfig = request.env[Pancake::Router::CONFIGURATION_KEY]
        konfig.router.generate(name, opts)
      end
    end # Generation
  end # Url
end # Pancake
