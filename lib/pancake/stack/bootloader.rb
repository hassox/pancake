module Pancake
  class Stack
    inheritable_inner_classes :BootLoader
    
    # The default bootloader is where the stack default bootloaders are stored
    # These are shared across all bootloaders
    class BootLoader # :nodoc:
      extend ::Pancake::BootLoaderMixin
    end
    
  end # Stack
end # Pancake

#################### Define the bootloaders here #############################
# :level => :init bootloaders only have the stack class available
# They do not have :stack available
# These are not run directly, but are run from inherited stacks
Pancake::Stack::BootLoader.add(:mount_applications, :level => :init) do
  def run!
    # Mount any stacks this stack may have in it.
    stack_class.roots.each do |root|
      Dir["#{root}/mounts/*/pancake.init"].each{|f| load f if File.exists?(f)}
    end
  end
end

Pancake::Stack::BootLoader.add(:load_configuration, :level => :init) do
  def run!
    stack_class.roots.each do |root|
      ["config.rb", "environments/#{Pancake.env}.rb"].each do |f|
        require "#{root}/config/#{f}" if File.exists?("#{root}/config/#{f}")
      end
    end
  end
end

Pancake::Stack::BootLoader.add(:load_application, :level => :init) do
  def run!
    stack_class.roots.each do |root|
      Dir["#{root}/app/**/*.rb"].each{|f| require f}
    end
  end
end

Pancake::Stack::BootLoader.add(:load_routes, :level => :init) do
  def run!
    stack_class.roots.each do |root|
      require "#{root}/config/router.rb" if File.exists?("#{root}/config/router.rb")
    end
  end
end

###### -================== Stack Building BootLoaders
# Pancake stacks need to be built with the following options
# MyApp::BootLoader.run!({
#   :stack_class  => self.class,
#   :stack        => self,
#   :app          => app,
#   :app_name     => app_name,
# })
#

Pancake::Stack::BootLoader.add(:stack_configuration) do
  def run!
    stack     = config[:stack]
    app_name  = config[:app_name] 

    Pancake.configuration.configs[app_name] = config[:config] if config[:config]
    stack.configuration(app_name) # get the configuration if there's none been specified
  end
end

Pancake::Stack::BootLoader.add(:initialize_application) do
  def run!
    config[:app] ||= config[:stack_class].new_app_instance
  end
end

Pancake::Stack::BootLoader.add(:build_middleware_stack) do
  def run!
    mwares = config[:stack_class].middlewares(Pancake.stack_labels)
    config[:stack].app = Pancake::Middleware.build(config[:app], mwares)
  end
end

Pancake::Stack::BootLoader.add(:router) do
  def run!
    unless config[:no_router]
      config[:stack].send(:prepare, :builder => Pancake::RouteBuilder) do |r|
        config[:stack_class].stack_routes.each{|sr| config[:stack].instance_exec(r, &sr)}
        r.map nil, :to => config[:stack].app # Fallback route 
      end
    end
  end
end
