puts "Loading Development configuration"

Pancake.configuration.configs(MyApp) do |config|
  config.foo = :foo
end

# Declare any middlewares that you want to use here
#
#  Example
# 
#  Pancake.use(MyMiddleware, :options){ # some block to pass to the middleware initializer }
#
#  MyApp::Stack.use(SomeMiddleware, :options){ #some block to pass to the middleware initializer }