# Provides the view context for the default `application` layout.
#
module Layouts::ApplicationViewContext
  extend ActiveSupport::Concern

  include LayoutStyles

  # Provides the title attribute for the current layout
  #
  # Can be overridden by page specific view_contexts.
  def title(_)
    'LogicalView'
  end
end
