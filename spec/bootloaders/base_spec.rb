require File.dirname(__FILE__) + '/../spec_helper'

describe "Pancake::Stack::BootLoader" do
  
  before(:each) do
    $captures = []
    clear_constants("FooStack")
    
    class FooStack < Pancake::Stack
    end
  end
  
  it "should not add the bootloader without it having a run! method" do
    lambda do
      FooStack::BootLoader.add(:foo){|s,c| :here }
    end.should raise_error
  end
  
  it "should allow me to add an application specific BootLoader" do
    FooStack::BootLoader.add(:my_initializer){|stack, config| def run!; :foo; end}  
    FooStack::BootLoader[:my_initializer].call(:stack, :config).should == :foo
  end
  
  it "should provide a bootloader instance" do
    FooStack::BootLoader.add(:my_initializer){|stack, config| def run!; :foo; end}
    FooStack::BootLoader[:my_initializer].should inherit_from(Pancake::BootLoaderMixin::Base)
  end
  
  it "should allow me to add multiple boot loaders" do
    FooStack::BootLoader.add(:foo){|s,c| def run!; :foo; end}
    FooStack::BootLoader.add(:bar){|s,c| def run!; :bar; end}
    FooStack::BootLoader[:foo].call(:stack, :config).should == :foo
    FooStack::BootLoader[:bar].call(:stack, :config).should == :bar
  end
  
  it "should allow me to add a bootloader before another" do
    $captures.should be_empty
    FooStack::BootLoader.add(:foo){|s,c| def run!; $captures << :foo; end}
    FooStack::BootLoader.add(:bar){|s,c| def run!; $captures << :bar; end}
    FooStack::BootLoader.add(:baz, :before => :bar){|s,c| def run!; $captures << :baz; end}
    FooStack::BootLoader.run!
    $captures.should == [:foo, :baz, :bar]
  end
  
  it "should allow me to add a bootloader after another" do
    $captures.should be_empty
    FooStack::BootLoader.add(:foo){|s,c| def run!; $captures << :foo; end}
    FooStack::BootLoader.add(:bar){|s,c| def run!; $captures << :bar; end}
    FooStack::BootLoader.add(:baz, :after => :foo){|s,c| def run!; $captures << :baz; end}
    FooStack::BootLoader.run!
    $captures.should == [:foo, :baz, :bar]
  end
  
  it "should provide an arbitrarily complex setup" do
    $captures.should be_empty
    FooStack::BootLoader.add(:foo                       ){|s,c| def run!; $captures << :foo; end}
    FooStack::BootLoader.add(:bar                       ){|s,c| def run!; $captures << :bar; end}
    FooStack::BootLoader.add(:baz,    :after  => :foo   ){|s,c| def run!; $captures << :baz; end}
    FooStack::BootLoader.add(:paz,    :before => :baz   ){|s,c| def run!; $captures << :paz; end}
    FooStack::BootLoader.add(:fred,   :before => :bar   ){|s,c| def run!; $captures << :fred; end}
    FooStack::BootLoader.add(:barney, :after  => :fred  ){|s,c| def run!; $captures << :barney; end}
    
    FooStack::BootLoader.run!
    $captures.should == [:foo, :paz, :baz, :fred, :barney, :bar]
    $captures.should == FooStack::BootLoader.map{|name, bootloader| name}
  end
  
  describe "types" do
  
    it "should run bootloaders marked as :init" do
      FooStack::BootLoader.add(:bar, :level => :init ){|s,c| def run!; $captures << [:bar, :init   ]; end}
      FooStack::BootLoader.add(:baz, :level => :init ){|s,c| def run!; $captures << [:baz, :init   ]; end}
      FooStack::BootLoader.add(:paz, :level => :init, :before => :baz){|s,c| def run!; $captures << [:paz, :init]; end}
      
      FooStack::BootLoader.run!(:only => {:level => :init})
      $captures.should == [[:bar, :init], [:paz, :init], [:baz, :init]]
    end
    
    it "should run default level bootloaders without running :init bootloaders" do
      FooStack::BootLoader.add(:foo                  ){|s,c| def run!; $captures << [:foo, :default]; end}
      FooStack::BootLoader.add(:bar, :level => :init ){|s,c| def run!; $captures << [:bar, :init   ]; end}
      FooStack::BootLoader.add(:baz, :level => :init ){|s,c| def run!; $captures << [:baz, :init   ]; end}
      FooStack::BootLoader.add(:paz, :level => :init, :before => :baz){|s,c| def run!; $captures << [:paz, :init]; end}
      
      FooStack::BootLoader.run!
      $captures.should == [[:foo, :default]]
    end
    
    it "should run init or then default level bootloaders individually" do
      FooStack::BootLoader.add(:foo                  ){|s,c| def run!; $captures << [:foo, :default]; end}
      FooStack::BootLoader.add(:grh                  ){|s,c| def run!; $captures << [:grh, :default]; end} 
      FooStack::BootLoader.add(:bar, :level => :init ){|s,c| def run!; $captures << [:bar, :init   ]; end}
      FooStack::BootLoader.add(:ptf, :before => :grh ){|s,c| def run!; $captures << [:ptf, :default]; end} 
      FooStack::BootLoader.add(:baz, :level => :init ){|s,c| def run!; $captures << [:baz, :init   ]; end}
      FooStack::BootLoader.add(:paz, :level => :init, :before => :baz){|s,c| def run!; $captures << [:paz, :init]; end}
      
      FooStack::BootLoader.run!
      $captures.should == [[:foo, :default], [:ptf, :default], [:grh, :default]]
      $captures = []
      FooStack::BootLoader.run!(:only => {:level => :init})
      $captures.should == [[:bar, :init], [:paz, :init], [:baz, :init]]
    end
  end
end