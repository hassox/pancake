module Pancake
  module Generators
    class Micro < Base
      argument :stack_name, :banner => "Name of stack"

      desc "Generates a stack"
      def stack
        say "Creating The Stack For #{stack_name}"
        directory "micro/%stack_name%", stack_name
        template  File.join(self.class.source_root, "common/dotgitignore"), "#{stack_name}/.gitignore"
        template  File.join(self.class.source_root, "common/dothtaccess"),  "#{stack_name}/public/.htaccess"
      end


    end
  end
end
