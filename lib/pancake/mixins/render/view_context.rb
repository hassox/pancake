require 'any_view'
module Pancake
  module Mixins
    module Render
      class ViewContext
        # These are included as modules not for modularization, but because super can be called for the module versions
        include Tilt::CompileSite
        include AnyView::TiltBase

        class << self
          def capture_method_for(item)
            key = case item
                  when Template
                    item.renderer.class
                  when Tilt::Template
                    item
                  end
            AnyView::TiltBase.capture_methods[key]
          end

          def concat_method_for(item)
            key = case item
                  when Template
                    item.renderer.class
                  when Tilt::Template
                    item
                  end
            AnyView::TiltBase.concat_methods[key]
          end
        end

        attr_reader :_view_context_for

        def initialize(renderer_for = nil, opts = {})
          opts.keys.each do |k,v|
            instance_variable_set("@#{k}", v)
          end
          @_inherit_helper = InheritanceHelper.new
          @_view_context_for = renderer_for
        end

        def inherits_from(ntos, name_or_opts = nil, opts = {})
          name_or_template = case ntos
          when String, Symbol
            if ntos == :default!
              begin
                if @format
                  Pancake.default_base_template(:format => @format)
                else
                  Pancake.default_base_template
                end
              rescue
                :base
              end
            else
              ntos
            end
          when Pancake::Mixins::Render::Template
            ntos
          else
            if name_or_opts.kind_of?(Hash)
              opts = name_or_opts
              name_or_opts = nil
            end
            name_or_opts ||= ntos.base_template_name
            ntos.template(name_or_opts, opts)
          end
          @_inherit_helper.inherits_from = name_or_template
        end

        def content_block(label = nil, &block)
          return self if label.nil?
          current_label = @_inherit_helper.current_label
          @_inherit_helper.current_label = label
          capture_method = ViewContext.capture_method_for(_current_renderer)

          @_inherit_helper.blocks[label] << [block, capture_method]
          if @_inherit_helper.inherits_from.nil?
            result = _capture_content_block(label)
            send(ViewContext.concat_method_for(_current_renderer), result)
          end
          @_inherit_helper.current_label = current_label
        end

        def super
          @_inherit_helper.increment_super!
          result = _capture_content_block(@_inherit_helper.current_label)
          @_inherit_helper.decrement_super!
          result
        end

        def render(template, opts = {}, &blk)
          template = _view_context_for.template(template)
          raise TemplateNotFound unless template
          result = _with_renderer template do
            _current_renderer.render(self, opts, &blk) # only include the block once
          end

          if @_inherit_helper.inherits_from
            next_template = template.owner.template(@_inherit_helper.inherits_from)
            @_inherit_helper.inherits_from = nil
            result = _with_renderer next_template do
              render(next_template, opts)
            end
          end
          result
        end

        def partial(*args)
          _view_context_for.partial(*args)
        end

        def _with_renderer(renderer)
          orig_renderer = @_current_renderer
          @_current_renderer = renderer
          result = yield
          @_current_renderer = orig_renderer
          result
        end

        def _current_renderer
          @_current_renderer
        end

        private
        def _capture_content_block(label)
          blk, meth = @_inherit_helper.block_for(label)
          send(meth, &blk)
        end


        class InheritanceHelper
          attr_accessor :inherits_from, :current_label
          attr_reader   :blocks, :super_index

          def initialize
            @blocks = Hash.new{|h,k| h[k] = []}
            @super_index = 0
          end

          def block_for(label)
            @blocks[label][@super_index]
          end

          def increment_super!
            @super_index += 1
          end

          def decrement_super!
            @super_index -= 1
          end

        end
      end
    end
  end
end
