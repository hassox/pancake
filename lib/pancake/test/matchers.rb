module Pancake
  module Test
    module Matchers
      class MountMatcher
        def initialize(expected_app, path)
          @expected_app, @path = expected_app, path
        end

        def matches?(target)
          @target = target
          @ma = @target::Router.mounted_applications.detect{|m| m.mounted_app == @expected_app}
          if @ma
            @ma.mounted_app == @expected_app && @ma.mount_path == @path
          else
            false
          end
        end

        def failure_message_for_should
          if @ma
            "Expected #{@target} to mount #{@expected_app} at #{@path.inspect} but was mounted at #{@ma.mount_path.inspect}"
          else
            "Expected #{@target} to mount #{@expected_app} but it was not mounted"
          end
        end

        def failure_message_for_should_not
          if @ma
            "Expected #{@target} to not implement #{@expected_app} at #{@path} but it was mounted there"
          end
        end
      end # MountMatcher

      def mount(expected, path)
        MountMatcher.new(expected, path)
      end

      class InheritFrom
        def initialize(expected)
          @expected = expected
        end

        def matches?(target)
          @target = target
          @target.ancestors.include?(@expected)
        end

        def failure_message
          "expected #{@target} to inherit from #{@expected} but did not"
        end
      end

      def inherit_from(expected)
        InheritFrom.new(expected)
      end

    end # Matchers
  end # Test
end # Pancake
