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
Pancake::Stack::BootLoader.add(:load_mounted_inits, :level => :init) do
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

# Pancake stacks need to be built with the following options
# MyApp::BootLoader.run!({
#   :stack_class  => self.class,
#   :stack        => self,
#   :app          => app,
#   :app_name     => app_name,
# })
#
#


Pancake::Stack::BootLoader.add(:load_routes) do
  def run!
    stack_class.roots.each do |root|
      stack_class.paths_for(:router).each{|f| require f.join}
    end
  end
end

Pancake::Stack::BootLoader.add(:before_mount_applicaions) do
  def run!
    stack_class.before_mount_applications.each{|blk| blk.call}
  end
end

Pancake::Stack::BootLoader.add(:mount_applications) do
  def run!
    stack_class.router.mount_applications!
  end
end

Pancake::Stack::BootLoader.add(:initialize_application) do
  def run!
    config[:app] ||= stack_class.new_app_instance
  end
end

Pancake::Stack::BootLoader.add(:after_initialize_application) do
  def run!
    stack_class.after_initialize_application.each{|blk| blk.call}
  end
end

Pancake::Stack::BootLoader.add(:before_build_stack) do
  def run!
    stack_class.before_build_stack.each{|blk| blk.call}
  end
end

Pancake::Stack::BootLoader.add(:build_stack) do
  def run!
    mwares = stack_class.middlewares(Pancake.stack_labels)
    app = Pancake::Middleware.build(config[:app], mwares)
    app_config = Pancake.configuration.configs(config[:app_name])
    app_config.app   = app
    app_config.stack = stack_class
    app_config.router.configuration = app_config
  end
end

Pancake::Stack::BootLoader.add(:after_build_stack) do
  def run!
    stack_class.after_build_stack.each{|blk| blk.call}
  end
end
