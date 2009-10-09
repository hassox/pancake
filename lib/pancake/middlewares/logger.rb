require 'logger'
module Pancake
  module Middlewares
    class Logger
      def initialize(app)
        @app = app
      end

      def call(env)
        env[Pancake::Constants::ENV_LOGGER_KEY] ||= Pancake.logger
        @app.call(env)
      end
    end
  end
end
