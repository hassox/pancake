module Pancake
  module Middlewares
    class Static
      attr_accessor :app, :stack
      def initialize(app, stack)
        @app, @stack = app, stack
        unless Pancake::Paths === stack
          raise "#{self.class} needs to be initialized with a stack (or something including Pancake::Paths)"
        end
      end

      def call(env)
        static_file = nil
        root = stack.dirs_for(:public).detect do |root|
          file_name = File.join(root, env['PATH_INFO'])
          if File.file?(file_name)
            static_file = file_name
          elsif File.file?(file_name + ".html")
            static_file = file_name + ".html"
          end
        end

        if static_file
          Rack::Response.new(File.open(static_file)).finish
        else
          app.call(env)
        end
      end
    end
  end
end
