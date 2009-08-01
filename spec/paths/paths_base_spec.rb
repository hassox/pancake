require File.dirname(__FILE__) + '/../spec_helper'

describe Pancake::Paths do
  
  before(:each) do
    remove_consts!
    class ::Foo
      extend Pancake::Paths
    end
    @base_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "fixtures", "paths"))
  end
  
  after(:all) do
    remove_consts!
  end
  
  def remove_consts!
    Object.class_eval do 
      remove_const("Foo") if defined?(Foo)
    end
  end
  
  describe "pushing paths" do
    it "should push a single path" do
      Foo.push_path(:models, File.join(@base_path, "models"))
      Foo.dirs_for(:models).should == [File.join(@base_path,"models")]
    end
    
    it "should give me an empty array of paths when there have been no paths added" do
      Foo.dirs_for(:models).should == []
    end
    
    it "should raise and error if there are no paths specified" do
      lambda do
        Foo.push_path(:models)
      end.should raise_error(ArgumentError)
      
      lambda do
        Foo.push_path(:models, [])
      end.should raise_error(Pancake::Paths::NoRootsGiven)
    end
    
    it "should allow me to push multiple times to a single path group" do
      Foo.push_path(:models, File.join(@base_path, "models"))
      Foo.push_path(:models, File.join(@base_path, "stack", "models"))
      Foo.dirs_for(:models).should == [
        File.join(@base_path, "models"),
        File.join(@base_path, "stack", "models")
      ]
    end
    
    it "should allow me to push multiple path sets" do
      Foo.push_path(:models,      [File.join(@base_path, "models"), File.join(@base_path, "stack", "models")])
      Foo.push_path(:controllers, File.join(@base_path, "controllers"))
      Foo.push_path(:views,       File.join(@base_path, "stack","views"))
      Foo.dirs_for(:models).should == [
        File.join(@base_path, "models"),
        File.join(@base_path, "stack", "models")
      ]
      Foo.dirs_for(:controllers ).should == [File.join(@base_path, "controllers")]
      Foo.dirs_for(:views       ).should == [File.join(@base_path, "stack", "views")]
    end
    
    it "should reverse the dirs_for when specified" do
      Foo.push_path(:models,      [File.join(@base_path, "models"), File.join(@base_path, "stack", "models")])
      Foo.dirs_for(:models, :reverse => true).should == [
        File.join(@base_path, "stack", "models"),
        File.join(@base_path, "models")
      ]
    end
    
    describe "globs" do
      it "should allow me to supply a glob to associate with the path" do
        Foo.push_path(:models,  File.join(@base_path, "models"),      "**/*.rb")
        Foo.push_path(:models,  File.join(@base_path, "stack", "models"), "**/*.rb")
        Foo.dirs_and_glob_for(:models).should == [
          [File.join(@base_path, "models"),           "**/*.rb"],
          [File.join(@base_path, "stack", "models"),  "**/*.rb"]
        ]
      end
      
      it "should associate an empty glob when not specified" do
        Foo.push_path(:models, File.join("/foo","bar"))
        Foo.dirs_for(:models).should == ["/foo/bar"]
        Foo.dirs_and_glob_for(:models).should == [["/foo/bar", nil]]
      end
      
      it "should revers the dirs_and_globs when requested" do
        Foo.push_path(:models,  File.join(@base_path, "models"),      "**/*.rb")
        Foo.push_path(:models,  File.join(@base_path, "stack", "models"), "**/*.rb")
        result = Foo.dirs_and_glob_for(:models, :reverse => true)
        result.should == [
          [File.join(@base_path, "stack", "models"),  "**/*.rb"],
          [File.join(@base_path, "models"),           "**/*.rb"]
        ]
      end
    end
  end
  
  describe "reading paths" do
    before(:each) do
      @model_root = File.join(@base_path, "models")
      @stack_root = File.join(@base_path, "stack/models")
      Foo.push_path(:model, [@model_root, @stack_root], "**/*.rb")
    end
    
    it "should have model1.rb in the model paths" do
      Foo.paths_for(:model).should      include(File.join(@model_root, "model1.rb"))
      Foo.paths_for(:model).should      include(File.join(@model_root, "model2.rb"))
      Foo.paths_for(:model).should      include(File.join(@stack_root, "model3.rb"))
      Foo.paths_for(:model).should_not  include(File.join(@model_root, "model3.rb"))
    end
    
    it "should allow me to reverse the order of the roots" do
      result = Foo.paths_for(:model, :reverse => true)
      result.should      include(File.join(@model_root, "model1.rb"))
      result.should      include(File.join(@model_root, "model2.rb"))
      result.should      include(File.join(@model_root, "model3.rb"))
      result.should_not  include(File.join(@stack_root, "model3.rb"))
    end
  end
  
  describe "reading globs" do
  end
  
  describe "inherited paths" do
  end
  
end