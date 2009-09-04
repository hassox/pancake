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
      stack_class.paths_for(:config).each{|f| require f.join}
    end
  end
end

Pancake::Stack::BootLoader.add(:load_application, :level => :init) do
  def run!
    stack_class.roots.each do |root|
      [:models, :controllers].each do |type|
        stack_class.paths_for(type).each{|f| require f.join}
      end
    end
  end
end

Pancake::Stack::BootLoader.add(:load_routes, :level => :init) do
  def run!
    stack_class.roots.each do |root|
      stack_class.paths_for(:router).each{|f| require f.join}
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
#

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
     app_config = Pancake.configuration.configs(config[:app_name])
     router = config[:stack_class].router.dup
     app_config.router = router
     router.app = config[:stack].app
     router.configuration = app_config
   end
 end
end
