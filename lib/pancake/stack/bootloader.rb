module Pancake
  class Stack
    # The default bootloader is where the stack default bootloaders are stored
    # These are shared across all bootloaders
    class BootLoader # :nodoc:
      extend ::Pancake::BootLoaderMixin
    end
    
    ## Add the bootloaders to the new application stack
    Pancake::Stack.on_inherit do |base, parent|
      this_self = parent
      base.class_eval do
        class self::BootLoader
          extend ::Pancake::BootLoaderMixin
        end
        self::BootLoader.stack = self
        self::BootLoader.reset!
        this_self::BootLoader.copy_to(self::BootLoader)      
      end
    end # Pancake::Stack.on_inherit
    
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