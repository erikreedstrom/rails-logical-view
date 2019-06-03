module ViewContext
  extend ActiveSupport::Concern

  module ClassMethods
    # Sets the controller specific view context module.
    # This module will be mixed into the extended view context class.
    def view_context(context_module)
      @_view_context_module = context_module
    end

    attr_internal_reader :view_context_module
  end

  # Returns anonymous class that includes a layout view context
  # and a controller specific view context, if defined.
  # Extends the default `view_context_class` defined by `ActionView::Rendering`.
  #
  # @see ActionView::Rendering#view_context_class
  def extended_view_context_class
    @_extended_view_context_class ||= begin
      view_context_module = self.class.view_context_module

      layout_context_module = define_layout_context_module

      Class.new(view_context_class) do
        include layout_context_module if layout_context_module.present?
        include view_context_module if view_context_module.present?
      end
    end
  end

  # Returns extended view context for controller.
  #
  # @see ActionView::Rendering#view_context
  def view_context
    extended_view_context_class.new(view_renderer, view_assigns, self)
  end

  private

  # Will return `nil` if no view context has been declared
  def define_layout_context_module
    # Actions without layouts will have no layout view context
    return unless action_has_layout?

    layout = send(:_layout, formats)
    # If layout is not a string or symbol, we derive
    # the class constant from its virtual path.
    #
    # 'layouts/application' => Layouts::ApplicationViewContext
    if layout.kind_of?(ActionView::Template)
      "#{layout.virtual_path.camelcase}ViewContext".safe_constantize
    else
      "Layouts::#{layout.to_s.camelcase}ViewContext".safe_constantize
    end
  end
end
