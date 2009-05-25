module Pancake
  def self.get_root(file)
    File.expand_path(File.dirname(file))
  end
  
  class Stack
    class << self
      # Get the roots that are applicable for this stack
      # :api: public
      def roots
        @roots ||= []
      end # roots
    end # self
  end # Panckae
end # Stack