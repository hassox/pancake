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
          root = File.expand_path(root)
          file_name = File.expand_path(File.join(root, env['PATH_INFO']))

          # If the client is asking for files outside the public directory, return missing
          # i.e. get "/../../foo.secret"
          if file_name !~ /^#{root}/
            return Rack::Response.new("Not Found", 404).finish
          end

          # If we get to here and the file exists serve it
          if File.file?(file_name)
            static_file = file_name
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
