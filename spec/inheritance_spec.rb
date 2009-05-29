require File.dirname(__FILE__) + '/spec_helper'

describe "Pancake Inheritance" do
  describe "on inherit hook" do
  
    before(:each) do
      clear_constants(:MyFoo, :OtherFoo, :FutherFoo, :SomeFoo, :DeeperFoo)
      class ::MyFoo 
        extend Pancake::Hooks::OnInherit
      end
    
      ::MyFoo.on_inherit do |base, parent|
        $inherited_capture << {:base => base, :parent => parent}
      end
      
      $inherited_capture = []
    end
  
    it "should provide on_inherit callbacks" do
      class ::OtherFoo < MyFoo; end
      $inherited_capture.should  == [{:base => OtherFoo, :parent => MyFoo}]
    end
    
    it "should inherit multiple times" do
      class ::OtherFoo < MyFoo; end
      class ::FurtherFoo < OtherFoo; end
      $inherited_capture.should == [{:base => OtherFoo, :parent => MyFoo}, {:base => FurtherFoo, :parent => OtherFoo}]
    end
    
    it "should allow for multiple callbacks" do
      MyFoo.on_inherit{|base, parent| $inherited_capture << :second}
      class ::OtherFoo < MyFoo; end
      $inherited_capture.should == [{:base => OtherFoo, :parent => MyFoo}, :second]
    end
    
    it "should allow for multiple callbacks that are inherited" do
      MyFoo.on_inherit{|base, parent| $inherited_capture << :second}
      class ::OtherFoo < MyFoo; end
      $inherited_capture = []
      OtherFoo.on_inherit{|base, parent| $inherited_capture << :inherited}
      class ::SomeFoo < OtherFoo; end
      $inherited_capture.should == [{:base => SomeFoo, :parent => OtherFoo}, :second, :inherited]      
    end
    
    it "should not pollute the parent with the child inherited hooks" do
      class ::OtherFoo < MyFoo; end
      $inherited_capture = []
      OtherFoo.on_inherit{|b,p| $inherited_captuer << :should_not_be_in_there}
      class ::SomeFoo < MyFoo; end
      $inherited_capture.should == [{:base => SomeFoo, :parent => MyFoo}]
    end
  end # "on inherit hook"
  
  describe "inheritable inner classes" do
    
    before(:each) do
      clear_constants(:MyFoo, :OtherFoo, :InnerFoo, :SomeFoo, :DeeperFoo)
      
      class ::MyFoo
        inheritable_inner_classes :InnerFoo
        class InnerFoo; end
      end
    end
    
    it "should inherit the inner class along with the outer class" do
      class ::OtherFoo < MyFoo; end
      OtherFoo::InnerFoo.should inherit_from(MyFoo::InnerFoo)
    end
    
    it "should inherit the inner class multiple times" do
      class ::OtherFoo < MyFoo; end
      class ::SomeFoo < OtherFoo; end
      class ::DeeperFoo < SomeFoo; end
      SomeFoo::InnerFoo.should inherit_from(OtherFoo::InnerFoo)
      DeeperFoo::InnerFoo.should inherit_from(SomeFoo::InnerFoo)
    end
    
    it "should allow additional inner classes to be declared without polluting the parent" do
      class ::OtherFoo < MyFoo
        inheritable_inner_classes :SomeDeepFoo
        class SomeDeepFoo; end
      end
      
      class ::SomeFoo < MyFoo; end
      class ::DeeperFoo < ::OtherFoo; end
      
      SomeFoo::InnerFoo.should inherit_from(MyFoo::InnerFoo)
      SomeFoo.const_defined?(:SomeDeepFoo).should be_false
      
      DeeperFoo::InnerFoo.should inherit_from(OtherFoo::InnerFoo)
      DeeperFoo::SomeDeepFoo.should inherit_from(OtherFoo::SomeDeepFoo)
    end

  end # "inheritable inner classes"
end