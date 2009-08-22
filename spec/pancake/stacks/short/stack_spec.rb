require File.dirname(__FILE__) + '/../../../spec_helper'

describe Pancake::Stacks::Short do
  
  before do
    class ::ShortFoo < Pancake::Stacks::Short; end
  end
  
  after do 
    clear_constants "ShortFoo"
  end
  

end