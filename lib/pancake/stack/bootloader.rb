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
Pancake::Stack::BootLoader.add(:mount_applications, :level => :init) do
  def run!
    # Mount any stacks this stack may have in it.
    stack.roots.each do |root|
      Dir["#{root}/mounts/*/pancake.init"].each{|f| load f if File.exists?(f)}
    end
  end
end