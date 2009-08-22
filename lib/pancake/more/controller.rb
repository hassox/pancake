path = File.dirname(__FILE__)
%w(
  controller/base
).each {|file| require File.join(path, file)}