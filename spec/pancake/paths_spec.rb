require 'spec_helper'

describe Pancake::Paths do

  def fixture_root
    File.expand_path(File.join(File.dirname(__FILE__), "fixtures", "paths"))
  end

  before(:each) do
    remove_consts!
    class ::Foo
      extend Pancake::Paths
    end
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

  describe "setting roots" do
    it "should allow me to set roots" do
      Foo.roots.should == []
      Foo.roots << fixture_root
      Foo.roots.should == [fixture_root]
    end
  end

  describe "pushing paths" do
    before do
      Foo.roots << fixture_root
    end

    it "should push a single path" do
      Foo.push_paths(:models, "models")
      Foo.dirs_for(:models).should == [File.join(fixture_root,"models")]
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
      Foo.push_paths(:models, "models")
      Foo.push_paths(:models, "stack/models")
      Foo.dirs_for(:models).should == [
        File.join(fixture_root, "models"),
        File.join(fixture_root, "stack", "models")
      ]
    end

    it "should allow me to push multiple path sets" do
      Foo.push_paths(:models,      ["models", "stack/models"])
      Foo.push_paths(:controllers, "controllers")
      Foo.push_paths(:views,       "stack/views")
      Foo.dirs_for(:models).should == [
        File.join(fixture_root, "models"),
        File.join(fixture_root, "stack", "models")
      ]
      Foo.dirs_for(:controllers ).should == [File.join(fixture_root, "controllers")]
      Foo.dirs_for(:views       ).should == [File.join(fixture_root, "stack", "views")]
    end

    it "should reverse the dirs_for when specified" do
      Foo.push_paths(:models,      ["models", "stack/models"])
      Foo.dirs_for(:models, :invert => true).should == [
        File.join(fixture_root, "stack", "models"),
        File.join(fixture_root, "models")
      ]
    end

    describe "globs" do
      it "should allow me to supply a glob to associate with the path" do
        Foo.push_paths(:models,  "models",        "**/*.rb")
        Foo.push_paths(:models,  "stack/models",  "**/*.rb")
        Foo.dirs_and_glob_for(:models).should == [
          [File.join(fixture_root, "models"),           "**/*.rb"],
          [File.join(fixture_root, "stack", "models"),  "**/*.rb"]
        ]
      end

      it "should associate an empty glob when not specified" do
        Foo.push_paths(:models, "foo/bar")
        Foo.dirs_for(:models).should == [File.join(fixture_root, "foo/bar")]
        Foo.dirs_and_glob_for(:models).should == [[File.join(fixture_root, "foo/bar"), nil]]
      end

      it "should revers the dirs_and_globs when requested" do
        Foo.push_paths(:models,  "models",      "**/*.rb")
        Foo.push_paths(:models,  "stack/models", "**/*.rb")
        result = Foo.dirs_and_glob_for(:models, :invert => true)
        result.should == [
          [File.join(fixture_root, "stack", "models"),  "**/*.rb"],
          [File.join(fixture_root, "models"),           "**/*.rb"]
        ]
      end
    end
  end

  describe "reading paths" do
    before(:each) do
      @model_root = File.join(fixture_root, "models")
      @stack_root =  File.join(fixture_root, "stack/models")
      Foo.roots << fixture_root
      Foo.push_paths(:model, ["models", "stack/models"], "**/*.rb")
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
      Foo.push_paths(:model,      "models")
      Foo.push_paths(:controller, "controllers")
      Foo.roots << fixture_root
      class ::Bar < Foo; end
    end

    it "should inherit paths from the parent" do
      Bar.dirs_for(:model).should       == [File.join(fixture_root, "models")]
      Bar.dirs_for(:controller).should  == [File.join(fixture_root, "controllers")]
    end

    it "should let me add to the collection from the parent" do
      Bar.push_paths(:model, "stack/models")
      Bar.dirs_for(:model).should == [
        File.join(fixture_root, "models"),
        File.join(fixture_root, "stack/models")
      ]
    end

    it "should not bleed paths back up to the parent" do
      Bar.push_paths(:model, "stack/models")
      Foo.dirs_for(:model).should == [File.join(fixture_root, "models")]
    end

    it "should not bleed paths over to a sibling class" do
      class ::Baz < Foo; end
      Bar.push_paths(:model, "stack/models")
      Baz.push_paths(:model, "baz/paths")
      Bar.dirs_for(:model).should == [
        File.join(fixture_root, "models"),
        File.join(fixture_root, "stack/models")
      ]
      Baz.dirs_for(:model).should == [
        File.join(fixture_root, "models"),
        File.join(fixture_root, "baz/paths")
      ]
      Foo.dirs_for(:model).should == [File.join(fixture_root, "models")]
    end

    it "should inherit multpile times" do
      class ::Baz < Bar; end
      Bar.push_paths(:model, "bar/path")
      Baz.dirs_for(:model).should == [
        File.join(fixture_root, "models"),
        File.join(fixture_root, "bar/path")
      ]
    end
  end
end
