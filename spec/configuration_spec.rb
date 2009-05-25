require File.dirname(__FILE__) + '/spec_helper'

describe "Pancake::Configuration" do
  
  it "should let me make a new configuration" do
    conf_klass = Pancake::Configuration.make
    conf_klass.should inherit_from(Pancake::Configuration::Base)
  end
  
  describe "usage" do
    before(:each) do
      @Conf = Pancake::Configuration.make
    end
    
    it "should let me set defaults" do
      @Conf.default :foo, :bar
      c = @Conf.new
      c.foo.should == :bar
      @Conf.new.foo.should == :bar
    end
    
    it "should let me set a description on the default" do
      @Conf.default :foo, :bar
      @Conf.default :bar, :baz, "A description of bar"
      c = @Conf.new
      c.foo.should == :bar
      c.bar.should == :baz
      c.defaults[:foo][:description].should == ""
      c.defaults[:bar][:description].should == "A description of bar"
    end
    
    it "should allow me to make multiple different configuration objects without polluting each other" do
      c1 = Pancake::Configuration.make
      c2 = Pancake::Configuration.make
      c1.default :foo, :bar
      c2.default :foo, :baz, "A description of foo"
      c1i, c2i = c1.new, c2.new
      c1i.foo.should == :bar
      c1i.defaults[:foo][:value].should == :bar
      c1i.defaults[:foo][:description].should == ""
      c2i.foo.should == :baz
      c2i.defaults[:foo][:value].should == :baz
      c2i.defaults[:foo][:description].should == "A description of foo"
    end  
    
    it "should allow me to define defaults in the make block" do
      c1 = Pancake::Configuration.make do
        default :foo, :bar, "Foo Desc"
        default :baz, 42,   "The Answer"
      end
      c = c1.new
      c.foo.should == :bar
      c.baz.should == 42
    end    
    
    it "should overwrite the default values" do
      @Conf.default :foo, :bar
      c = @Conf.new
      c.foo = :baz
      c.foo.inspect
      c.foo.should == :baz
      c.defaults[:foo][:value].should == :bar
    end
    
    it "should not add a default value for values I set blindly" do
      c = @Conf.new
      c.bar.should be_nil
      c.defaults.keys.should_not include(:bar)
    end
    
    it "should allow me to set a value then the default and not get mixed up" do
      c = @Conf.new
      c.bar = :foo
      c.defaults[:bar][:value].should == nil
    end
    
    it "should let me declare defaults after I've initizlied the configuartion object" do
      c = @Conf.new
      @Conf.default :foo, :bar
      c.foo.should == :bar
    end
    
    it "should give me a list of the current defaults" do
      @Conf.default :foo, :bar
      @Conf.default :bar, :baz, "Some description"
      c = @Conf.new
      c.defaults.should == {
        :foo => {
          :description  => "",
          :value        => :bar
        },
        :bar => {
          :description  => "Some description",
          :value        => :baz
        }
      }
    end
    
    it "should give me a description for a default" do
      @Conf.default :foo, :bar, "foo description"
      c = @Conf.new
      c.description_for(:foo).should == "foo description"
    end  
    
    it "should give me a list of values for the current object" do
      @Conf.default :foo, :bar
      c = @Conf.new
      c.values.should == {}
      c.foo
      c.values.should == {:foo => :bar}
      c.baz = :paz
      c.values.should == {:foo => :bar, :baz => :paz}
    end
    
    it "should allow me to define methods in the make block" do
      c = Pancake::Configuration.make do
        default :foo, :bar
        
        default :bar do
          foobar
        end
        
        def foobar
          "This is in foobar"
        end
      end
      
      ci = c.new
      ci.foo.should == :bar
      ci.bar.should == "This is in foobar"
    end
    
    it "should not cache the default when it's defined in a block" do
      c = Pancake::Configuration.make do
        default :foo do
          bar
        end
        default :bar, :bar
      end
      ci = c.new
      ci.foo.should == :bar
      ci.bar = :baz
      ci.bar.should == :baz
      ci.foo.should == :baz
    end
    
    it "should overwrite the proc when set directly" do
      @Conf.default :foo, :foo
      @Conf.default(:bar){ foo }
      ci = @Conf.new
      ci.bar.should == :foo
      ci.foo = :baz
      ci.bar.should == :baz
      ci.bar = :foobar
      ci.bar.should == :foobar      
    end
    
    it "should not cache nil when accessing before defaults are set" do
      c = @Conf.new
      c.foo.should be_nil
      @Conf.default :foo, :bar
      c.foo.should == :bar
      c.foo = :baz
      c.foo.should == :baz
    end
    
  end
end