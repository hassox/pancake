require 'rack/test'
class Pancake::Console
  attr_accessor :app
  include Rack::Test::Methods

  def initialize(stack)
    @stack    = stack
    @app      = stack.stackup(:master => true)
    app = self
    Object.__send__(:define_method, :stack){ app }
    Pancake.handle_errors! true
    Pancake.configuration.log_to_file = false

    require 'irb'
    require 'irb/completion'
    if File.exists? ".irbrc"
      ENV['IRBRC'] = ".irbrc"
    end

    catch(:IRB_EXIT) do
      IRB.start
      exit
    end
  end
end


