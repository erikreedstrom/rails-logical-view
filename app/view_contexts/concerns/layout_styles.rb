# Provides methods to set template classes based on current layout, controller, and action.
#
module LayoutStyles
  extend ActiveSupport::Concern

  # Returns a string of class names to be used in the template,
  # typically assigned to the `body` tag.
  #
  # @param controller [String] the namespaced controller
  # @param action [String] the current action
  # @return [String] the class names for the current layout, controller, and action
  #
  # @example
  #   irb> template_class_names('client_services/dashboard', 'index')
  #   => 'client-services client-services-dashboard client-services-dashboard--index'
  def template_class_names(controller, action)
    (layout_class_names + controller_class_names(controller, action)).uniq.compact.join(' ')
  end

  private

  def controller_class_names(controller, action)
    return [] unless controller.present?

    class_names = controller.split('/').inject([]) do |classes, page_scope|
      prefix = classes.empty? ? '' : "#{classes.last}-"
      classes << "#{prefix}#{page_scope}".dasherize
    end

    class_names << "#{class_names.last}--#{action}".dasherize
  end

  def layout_class_names
    return [] unless self.controller.action_has_layout?

    layout = self.controller.send(:_layout, formats)
    # If layout is not a string or symbol; i.e. ActiveView:Template,
    # we derive the class constant from its virtual path, removing `layouts/`.
    #
    # 'layouts/application' => 'application'
    layout_name = if layout.respond_to?(:virtual_path)
                    layout.virtual_path
                  else
                    layout.to_s
                  end

    Array.wrap(layout_name.gsub('layouts/', '').dasherize)
  end
end
