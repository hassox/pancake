require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Pancake::MimeTypes do
  before do
    Pancake::MimeTypes.reset!
  end
  
  it "should have many types" do
    Pancake::MimeTypes.types.should be_an(Array)
  end

  it "should have a type for each mime type defined in Rack::Mime::MIME_TYPES" do
    Rack::Mime::MIME_TYPES.each do |ext, type|
      ext =~ /\.(.*)$/
      t = Pancake::MimeTypes.type_by_extension($1)
      t.should_not be_nil
      t.should be_an_instance_of(Pancake::MimeTypes::Type)
      t.type_strings.should include(type)
    end
  end

  it "should find the type from an extension" do
    t = Pancake::MimeTypes.type_by_extension("html")
    t.should_not be_nil
    t.type_strings.should include("text/html")
  end
  
  it "should allow me to add a new mime type" do
    t = Pancake::MimeTypes::Type.new("foo", "text/foobar")
    type = Pancake::MimeTypes.type_by_extension("foo")
    type.should_not be_nil
    type.type_strings.should have(1).item3
    type.type_strings.should include("text/foobar")
  end
  
  describe Pancake::MimeTypes::Type do
    include Pancake::MimeTypes

    before do
      @type = Pancake::MimeTypes::Type.new("html", "text/html")
    end
    
    it "should have one extension" do
      @type.extension.should == "html"
    end
    
    it "should tell me the type strings" do
      @type.type_strings.should include("text/html")
    end

    it "should allow me to add type strings" do
      @type.type_strings << "text/foo_html"
      @type.type_strings.should include("text/foo_html")
    end

    it "should not add duplicate type strings" do
      @type.type_strings.should have(1).item
      @type.type_strings << "text/html"
      @type.type_strings.should have(1).item
      @type.type_strings.should include("text/html")
    end

    it "should add non duplicate tpe strying" do
      @type.type_strings.should have(1).item
      @type.type_strings << "text/foo_html"
      @type.type_strings.should have(2).items
      @type.type_strings.should include("text/foo_html")
    end
  end

  describe "grouping types" do
    it "should allow me to create a group of mime types" do
      Pancake::MimeTypes.group(:html).should be_an(Enumerable)
    end

    it "should allow me to add mime types to the group" do
      Pancake::MimeTypes.group_as(:foo, "html", "xhtml")
      r = Pancake::MimeTypes.group(:foo)
      r.should have(2).items
      r.should include(Pancake::MimeTypes.type_by_extension("html"))
      r.should include(Pancake::MimeTypes.type_by_extension("xhtml"))
    end

    it "should allow me to add to a group without creating duplicates" do
      t = Pancake::MimeTypes::Type.new("foo", "foo/bar")
      Pancake::MimeTypes.group_as(:bar, "xhtml", "html")
      Pancake::MimeTypes.group(:bar).should have(2).items
      Pancake::MimeTypes.group(:bar).should_not include(t)
      Pancake::MimeTypes.group_as(:bar, "html", "foo", "xhtml")
      Pancake::MimeTypes.group(:bar).should have(3).items
      Pancake::MimeTypes.group(:bar).should include(t)
    end
    
    it "should allow me to look up a mime type via a string or symbol identifier" do
      Pancake::MimeTypes.group(:html).should eql Pancake::MimeTypes.group("html")
    end
    
    it "should be empty empty when accessing a non existant mime type" do
      r = Pancake::MimeTypes.group(:not_a_mime)
      r.should_not be_nil
      r.should be_empty
      r.should respond_to(:each)
    end
    
    it "should populate the group with the types when first acessing when a type with that extension exists" do
      r = Pancake::MimeTypes.group(:xml)
      r.should_not be_empty
      r.each do |t|
        t.should be_an_instance_of(Pancake::MimeTypes::Type)
      end
    end
  end

  describe "prepared groups" do
    it "should prepare the html group" do
      g = Pancake::MimeTypes.group(:html)
      g.should have(3).items
      ["html", "htm", "xhtml"].each do |ext|
        t = Pancake::MimeTypes.type_by_extension(ext)
        g.should include(t)
      end
    end
    
    it "should parepare the text group" do
      g = Pancake::MimeTypes.group(:text)
      g.should have(2).items
      ["text", "txt"].each do |ext|
        t = Pancake::MimeTypes.type_by_extension(ext)
        g.should include(t)
      end
    end

    it "should prepare the svg group" do
      g = Pancake::MimeTypes.group(:svg)
      g.should have(2).items
      ["svg", "svgz"].each do |ext|
        t = Pancake::MimeTypes.type_by_extension(ext)
        g.should include(t)
      end
    end
    
    
    it "should add the text/xml to the xml format" do
      t = Pancake::MimeTypes.type_by_extension("xml")
      t.type_strings.should include("text/xml", "application/xml")
    end
    
  end
  
  
  describe "format from accept type" do
    it "should return the first matching type" do
      accept_type = "text/plain"
      group, r = Pancake::MimeTypes.negotiate_accept_type(accept_type, :text)
      group.should == :text
      r.should_not be_nil
      r.type_strings.should include("text/plain")
    end
    
    it "should return the first type if the matching type is */*" do
      accept_type = "*/*;application/xml"
      group, r = Pancake::MimeTypes.negotiate_accept_type(accept_type, :text, :xml, :html)
      group.should == :text
      r.should_not be_nil
      r.type_strings.should include("text/plain")
    end
    
    it "should return nil if there is no matching class" do
      accept_type = "text/xml"
      group, r = Pancake::MimeTypes.negotiate_accept_type(accept_type, :text, :html)
      r.should be_nil
      group.should be_nil
    end
    
    it "should return a type when it is not in the first position" do
      accept_type = "text/xml, text/html,text/plain;"
      group, r = Pancake::MimeTypes.negotiate_accept_type(accept_type, :svg, :text)
      group.should == :text
      r.should_not be_nil
      r.type_strings.should include("text/plain")
      r.extension.should == "text"
    end

    it "should recognize the type from a quality value" do
      accept_type = "text/plain;q=0.5,text/html;q=0.8"
      group, r = Pancake::MimeTypes.negotiate_accept_type(accept_type, :text, :html)
      group.should == :html
      r.should_not be_nil
      r.type_strings.should include("text/html")
      r.extension.should == "html"
    end
    
    
    
  end
  
end

