module Pancake
  module Mixins
    module Render
      class ViewContext
        class << self
          def _concat_methods
            @_concat_methods ||= {}
          end

          def _capture_methods
            @_capture_methods ||= {}
          end

          def capture_method_for(item)
            key = case item
                  when Template
                    item.renderer.class
                  when Tilt::Template
                    item
                  end
            _capture_methods[key]
          end

          def concat_method_for(item)
            key = case item
                  when Template
                    item.renderer.class
                  when Tilt::Template
                    item
                  end
            _concat_methods[key]
          end

        end

        _capture_methods[Tilt::HamlTemplate] = :_haml_capture
        _capture_methods[Tilt::ERBTemplate ] = :_erb_capture
        _concat_methods[ Tilt::HamlTemplate] = :_haml_concat
        _concat_methods[ Tilt::ERBTemplate ] = :_erb_concat

        module Renderer
          def render(template, opts = {})
            template = _view_context_for.template(template)
            raise TemplateNotFound unless template
            result = _with_renderer template do
              _current_renderer.render(self, opts)
            end

            if @_inherit_helper.inherits_from
              next_template = _view_context_for.template(@_inherit_helper.inherits_from)
              @_inherit_helper.inherits_from = nil
              result = _with_renderer next_template do
                _current_renderer.render(self,opts)
              end
            end
            result
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
        end # Renderer

        module Capture
          def capture(opts = {}, &block)
            opts[:_capture_method] ||= ViewContext.capture_method_for(_current_renderer)
            raise "CaptureMethod not specified" unless opts[:_capture_method]
            send(opts[:_capture_method], block)
          end

          def concat(string, opts = {})
            opts[:_concat_method] ||= ViewContext.concat_method_for(_current_renderer)
            raise "ConcatMethod not specified" unless opts[:_concat_method]
            send(opts[:_concat_method], string)
          end

          def _haml_capture(block)
            with_haml_buffer Haml::Buffer.new(nil, :encoding => "UTF-8") do
              capture_haml(&block)
            end
          end

          def _erb_capture(block)
            _out_buf, @_out_buf = @_out_buf, ""
            block.call
            ret = @_out_buf
            @_out_buf = _out_buf
            ret
          end

          def _haml_concat(string)
            haml_concat string
          end

          def _erb_concat(string)
            @_out_buf << string
          end
        end # Capture

        module ContentInheritance
          def initialize(*args)
            super()
            @_inherit_helper = Helper.new
          end

          def inherits_from(name_or_template)
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

          private
          def _capture_content_block(label)
            blk, meth = @_inherit_helper.block_for(label)
            send(meth, blk)
          end

          class Helper
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
      end # ViewContext
    end
  end
end
