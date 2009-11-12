module Pancake
  module Generators
    class Short < Base
      argument :stack_name, :banner => "Name of stack"

      desc "Generates a short stack"
      def stack
        say "Creating The Short Stack For #{stack_name}"
        directory "short/%stack_name%", stack_name
        template  File.join(self.class.source_root, "common/dotgitignore"), "#{stack_name}/.gitignore"
        template  File.join(self.class.source_root, "common/dothtaccess"),  "#{stack_name}/lib/#{stack_name}/public/.htaccess"

        inside("#{stack_name}/lib/#{stack_name}/script") do
          run 'chmod +x console'
        end
      end


    end
  end
end
