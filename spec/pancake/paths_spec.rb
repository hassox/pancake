require File.dirname(__FILE__) + '/../spec_helper'

describe Pancake::Paths do
  
  before(:each) do
    remove_consts!
    class ::Foo
      extend Pancake::Paths
    end
    @base_path = File.expand_path(File.join(File.dirname(__FILE__), "fixtures", "paths"))
  end
  
  after(:all) do
    remove_consts!
  end
  
  def remove_consts!
    Object.class_eval do 
      remove_const("Foo") if defined?(Foo)
      remove_const("Bar") if defined?(Bar)
      remove_const("Baz") if defined?(Baz)
    end
  end
  
  describe "pushing paths" do
    it "should push a single path" do
      Foo.push_paths(:models, File.join(@base_path, "models"))
      Foo.dirs_for(:models).should == [File.join(@base_path,"models")]
    end
    
    it "should give me an empty array of paths when there have been no paths added" do
      Foo.dirs_for(:models).should == []
    end
    
    it "should raise and error if there are no paths specified" do
      lambda do
        Foo.push_paths(:models)
      end.should raise_error(ArgumentError)
      
      lambda do
        Foo.push_paths(:models, [])
      end.should raise_error(Pancake::Paths::NoPathsGiven)
    end
    
    it "should allow me to push multiple times to a single path group" do
      Foo.push_paths(:models, File.join(@base_path, "models"))
      Foo.push_paths(:models, File.join(@base_path, "stack", "models"))
      Foo.dirs_for(:models).should == [
        File.join(@base_path, "models"),
        File.join(@base_path, "stack", "models")
      ]
    end
    
    it "should allow me to push multiple path sets" do
      Foo.push_paths(:models,      [File.join(@base_path, "models"), File.join(@base_path, "stack", "models")])
      Foo.push_paths(:controllers, File.join(@base_path, "controllers"))
      Foo.push_paths(:views,       File.join(@base_path, "stack","views"))
      Foo.dirs_for(:models).should == [
        File.join(@base_path, "models"),
        File.join(@base_path, "stack", "models")
      ]
      Foo.dirs_for(:controllers ).should == [File.join(@base_path, "controllers")]
      Foo.dirs_for(:views       ).should == [File.join(@base_path, "stack", "views")]
    end
    
    it "should reverse the dirs_for when specified" do
      Foo.push_paths(:models,      [File.join(@base_path, "models"), File.join(@base_path, "stack", "models")])
      Foo.dirs_for(:models, :invert => true).should == [
        File.join(@base_path, "stack", "models"),
        File.join(@base_path, "models")
      ]
    end
    
    describe "globs" do
      it "should allow me to supply a glob to associate with the path" do
        Foo.push_paths(:models,  File.join(@base_path, "models"),      "**/*.rb")
        Foo.push_paths(:models,  File.join(@base_path, "stack", "models"), "**/*.rb")
        Foo.dirs_and_glob_for(:models).should == [
          [File.join(@base_path, "models"),           "**/*.rb"],
          [File.join(@base_path, "stack", "models"),  "**/*.rb"]
        ]
      end
      
      it "should associate an empty glob when not specified" do
        Foo.push_paths(:models, File.join("/foo","bar"))
        Foo.dirs_for(:models).should == ["/foo/bar"]
        Foo.dirs_and_glob_for(:models).should == [["/foo/bar", nil]]
      end
      
      it "should revers the dirs_and_globs when requested" do
        Foo.push_paths(:models,  File.join(@base_path, "models"),      "**/*.rb")
        Foo.push_paths(:models,  File.join(@base_path, "stack", "models"), "**/*.rb")
        result = Foo.dirs_and_glob_for(:models, :invert => true)
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
      Foo.push_paths(:model, [@model_root, @stack_root], "**/*.rb")
    end
    
    it "should have list all the paths for :model" do
      result = Foo.paths_for(:model).should == [
        [@model_root, "/model1.rb"],
        [@model_root, "/model2.rb"],
        [@model_root, "/model3.rb"],
        [@stack_root, "/model3.rb"]
      ]
    end
    
    it "should allow me to invert the order of the roots" do
      result = Foo.paths_for(:model, :invert => true).should == [
        [@stack_root, "/model3.rb"],
        [@model_root, "/model3.rb"],
        [@model_root, "/model2.rb"],
        [@model_root, "/model1.rb"]
      ]
    end
    
    it "should allow me to get the unique_paths" do
      result = Foo.unique_paths_for(:model).should == [
        [@model_root, "/model1.rb"],
        [@model_root, "/model2.rb"],
        [@stack_root, "/model3.rb"]
      ]
    end
    
    it "should allow me to invert the order of the unique_paths" do
      result = Foo.unique_paths_for(:model, :invert => true).should == [
        [@model_root, "/model3.rb"],
        [@model_root, "/model2.rb"],
        [@model_root, "/model1.rb"]
      ]
    end
  end
  
  describe "inherited paths" do
    before(:each) do
      Foo.push_paths(:model,      File.join(@base_path, "models"))
      Foo.push_paths(:controller, File.join(@base_path, "controllers"))
      class ::Bar < Foo; end
    end
    
    it "should inherit paths from the parent" do
      Bar.dirs_for(:model).should       == [File.join(@base_path, "models")]
      Bar.dirs_for(:controller).should  == [File.join(@base_path, "controllers")]
    end
    
    it "should let me add to the collection from the parent" do
      Bar.push_paths(:model, File.join(@base_path, "stack", "models"))
      Bar.dirs_for(:model).should == [
        File.join(@base_path, "models"),
        File.join(@base_path, "stack", "models")
      ]
    end
    
    it "should not bleed paths back up to the parent" do
      Bar.push_paths(:model, File.join(@base_path, "stack", "models"))
      Foo.dirs_for(:model).should == [File.join(@base_path, "models")]
    end
    
    it "should not bleed paths over to a sibling class" do
      class ::Baz < Foo; end
      Bar.push_paths(:model, File.join(@base_path, "stack", "models"))
      Baz.push_paths(:model, "/baz/paths")
      Bar.dirs_for(:model).should == [
        File.join(@base_path, "models"),
        File.join(@base_path, "stack", "models")
      ]
      Baz.dirs_for(:model).should == [
        File.join(@base_path, "models"),
        "/baz/paths"
      ]
      Foo.dirs_for(:model).should == [File.join(@base_path, "models")]
    end
    
    it "should inherit multpile times" do
      class ::Baz < Bar; end
      Bar.push_paths(:model, "/bar/path")
      Baz.dirs_for(:model).should == [
        File.join(@base_path, "models"),
        "/bar/path"
      ]
    end
  end
end