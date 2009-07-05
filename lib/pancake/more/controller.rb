path = File.dirname(__FILE__)
%w(
  controller/action_options
  controller/publish
  controller/base
  controller/errors
).each {|file| require File.join(path, file)}