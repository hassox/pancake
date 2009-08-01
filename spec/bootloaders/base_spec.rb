require File.dirname(__FILE__) + '/../spec_helper'

describe "Pancake::Stack::BootLoader" do
  
  before(:each) do
    $captures = []
    
    class ::FooStack < Pancake::Stack
      roots << File.join(Pancake.get_root(__FILE__), "..", "fixtures", "foo_stack")
    end
  end
  
  after(:each) do
    clear_constants(:FooStack)
  end
  
  it "should not add the bootloader without it having a run! method" do
    lambda do
      FooStack::BootLoader.add(:foo){|s,c| :here }
    end.should raise_error
  end
  
  it "should allow me to add an application specific BootLoader" do
    FooStack::BootLoader.add(:my_initializer){ def run!; :foo; end}  
    FooStack::BootLoader[:my_initializer].call({}).should == :foo
  end
  
  it "should provide a bootloader instance" do
    FooStack::BootLoader.add(:my_initializer){ def run!; :foo; end}
    FooStack::BootLoader[:my_initializer].should inherit_from(Pancake::BootLoaderMixin::Base)
  end
  
  it "should allow me to add multiple boot loaders" do
    FooStack::BootLoader.add(:foo){ def run!; :foo; end}
    FooStack::BootLoader.add(:bar){ def run!; :bar; end}
    FooStack::BootLoader[:foo].call({}).should == :foo
    FooStack::BootLoader[:bar].call({}).should == :bar
  end
  
  it "should allow me to add a bootloader before another" do
    $captures.should be_empty
    FooStack::BootLoader.add(:foo){ def run!; $captures << :foo; end}
    FooStack::BootLoader.add(:bar){ def run!; $captures << :bar; end}
    FooStack::BootLoader.add(:baz, :before => :bar){ def run!; $captures << :baz; end}
    FooStack.new
    $captures.should == [:foo, :baz, :bar]
  end
  
  it "should allow me to add a bootloader after another" do
    $captures.should be_empty
    FooStack::BootLoader.add(:foo){ def run!; $captures << :foo; end}
    FooStack::BootLoader.add(:bar){ def run!; $captures << :bar; end}
    FooStack::BootLoader.add(:baz, :after => :foo){ def run!; $captures << :baz; end}
    FooStack.new
    $captures.should == [:foo, :baz, :bar]
  end
  
  it "should provide an arbitrarily complex setup" do
    $captures.should be_empty
    FooStack::BootLoader.add(:foo                       ){ def run!; $captures << :foo; end}
    FooStack::BootLoader.add(:bar                       ){ def run!; $captures << :bar; end}
    FooStack::BootLoader.add(:baz,    :after  => :foo   ){ def run!; $captures << :baz; end}
    FooStack::BootLoader.add(:paz,    :before => :baz   ){ def run!; $captures << :paz; end}
    FooStack::BootLoader.add(:fred,   :before => :bar   ){ def run!; $captures << :fred; end}
    FooStack::BootLoader.add(:barney, :after  => :fred  ){ def run!; $captures << :barney; end}
    
    FooStack.new
    $captures.should == [:foo, :paz, :baz, :fred, :barney, :bar]
  end
  
  describe "types" do
  
    it "should run bootloaders marked as :init" do
      FooStack::BootLoader.add(:bar, :level => :init ){ def run!; $captures << [:bar, :init   ]; end}
      FooStack::BootLoader.add(:baz, :level => :init ){ def run!; $captures << [:baz, :init   ]; end}
      FooStack::BootLoader.add(:paz, :level => :init, :before => :baz){ def run!; $captures << [:paz, :init]; end}
      
      FooStack::BootLoader.run!(:only => {:level => :init})
      $captures.should == [[:bar, :init], [:paz, :init], [:baz, :init]]
    end
    
    it "should run init or then default level bootloaders individually" do
      FooStack::BootLoader.add(:foo                  ){ def run!; $captures << [:foo, :default]; end}
      FooStack::BootLoader.add(:grh                  ){ def run!; $captures << [:grh, :default]; end} 
      FooStack::BootLoader.add(:bar, :level => :init ){ def run!; $captures << [:bar, :init   ]; end}
      FooStack::BootLoader.add(:ptf, :before => :grh ){ def run!; $captures << [:ptf, :default]; end} 
      FooStack::BootLoader.add(:baz, :level => :init ){ def run!; $captures << [:baz, :init   ]; end}
      FooStack::BootLoader.add(:paz, :level => :init, :before => :baz){ def run!; $captures << [:paz, :init]; end}
      
      FooStack.new
      $captures.should == [[:bar, :init], [:paz, :init], [:baz, :init], [:foo, :default], [:ptf, :default], [:grh, :default]]
    end
    
    it "should inherit from the default boot loaders" do
      ::Pancake::Stack::BootLoader.add(:default_boot_loader_test){def run!; end}
      class ::Bario < Pancake::Stack; end
      Bario::BootLoader.map{|n,bl| n}.should include(:default_boot_loader_test)
    end
    
    it "should let me pass options to the bootloaders and pass them on" do
      FooStack::BootLoader.add(:foo){ def run!; config[:result] << :foo; end}
      FooStack::BootLoader.add(:bar){ def run!; config[:result] << :bar; end}
      
      opts = { :result => [] }
      FooStack.new(nil, opts)
      opts[:result].should == [:foo, :bar]
    end
  end
end