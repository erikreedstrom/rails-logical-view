# Logical Views in Rails

Rails can be painful when using in the absence of a proper view abstraction. Often, this is countered 
by creating global helpers, or by creating POROs and scattering them throughout the application. 
Though these techniques do not necessarily align with the software design paradigms of MVC, and present
additional questions. What goes in them? How and when are they instantiated? What relation do they have 
with the template and the controller?

We can, however, provide this abstraction by hooking onto a little know aspect of the Rails 
view rendering pipeline.

## Background

View contexts are part of the underlying view rendering in Rails, which provide the view renderer with scope and 
context for rendering templates. It's where the instance variables are assigned by the controller, defines what 
renderer will render the template, and is where the route and other helpers are injected.

> **What is a view, and why does it need context?**
>
> Rails defines a view as the markup being rendered. In many frameworks this is called the _Template_. 
> The code behind the template is what is typically called the _View_; 
> however, we'll stick with Rails nomenclature. In Rails, this is known as the _ViewContext_.

### A Custom ViewContext

The ViewContext is explicitly where one should expect to find view specific methods and computed fields. 
By creating a custom context, we can present isolated functionality to the view on a per controller basis. 

If one ventures into `ActionView::Rendering`, they will see the following snippet:

```ruby
# An instance of a view class. The default view class is 
# ActionView::Base
#
# The view class must have the following methods:
# View.new[lookup_context, assigns, controller]
#   Create a new ActionView instance for a controller 
#   and we can also pass the arguments.
# View#render(option)
#   Returns String with the rendered template
#
# Override this method in a module to change the default behavior.
def view_context
  view_context_class.new(view_renderer, view_assigns, self)
end
```

And `ActionView::Rendering` is included in every controller, providing a great extension point for us. 
Although, we *actually* want to use the `view_context_class` being defined in `ActionView::Rendering` as well; 
it's the anonymous class that provides the injections for route and other helpers.

The easiest way to accomplish providing our custom functionality then, is by extending this anonymous 
class with a module.

> **Why not use a Presenter?**
>
> The presenter pattern delegates to the model, which works for simple crud, but becomes unwieldy when the 
> view contains disparate information, multiple models, or general helper methods
>
> By using a custom view context, we create similar functionality but isolated from the model and specific to 
> views related to the controller actions, and although not well documented, following *The Rails Way*.

#### Extending `view_context`

The following concern provides us with the macro `view_context`, taking the module name as its sole argument.
This macro extends the existing anonymous class with our module, and redefines the `view_context`instance method 
to use it when generating our view context.

```ruby
module ViewContext
  extend ActiveSupport::Concern

  module ClassMethods
    def view_context(mod)
      extended_view_context_class = 
        Class.new(view_context_class) { include mod }

      define_method :view_context do
        extended_view_context_class
          .new(view_renderer, view_assigns, self)
      end
    end
  end
end
```

## Usage

View contexts are defined as modules, and are constructed in the same manner as a normal, global helper file.

```ruby
module AwesomeViewContext
  def sweet
    'I know!'
  end
end
```

There is one view context per controller. This ensures that context is consistent between various actions, 
and the same functionality is available regardless. This does not mean, however, that each controller 
should have its own view context. In cases where controllers resolve the same resource, but have been split 
across actions, a singular view context is likely warranted.

The `ViewContext` mix-in provides the macro `view_context`, which accepts the view context module constant 
as its sole argument.

```ruby
class AwesomeController < ApplicationController
  include ViewContext

  view_context AwesomeViewContext
  ...
end
```

> Although we are including `ViewContext` explicitly in the controller for this example, in the application 
> this is done at the base controller level; i.e. `ApplicationController`.

Templates can now use the functionality provided by the context. 

Provided the following template:

```erb
<span class="awesome"><%= sweet %></span>
```

This markup will be rendered:

```erb
<span class="awesome">I know!</span>
```

Given the custom context simply extends the existing `view_context_class`, all helper methods and instance 
variables defined in the controller are available, as one would expect.

### Layout Contexts

Although controllers may define a single view context module, the controller will also lookup its layout and 
additionally include a corresponding context if it has been defined.

These typically are located under `view_contexts/layouts` and are namespaced under `Layouts`. Their main use
is to provide layout-wide functionality common to multiple views.

**view_contexts/layouts/application_view_context.rb**
```Ruby
module Layouts::ApplicationViewContext
  include LayoutStyles  
end
```

## Passing Local Assigns

Rails has a tendency to be magic to a fault. Since template rendering is not typically explicit, many developers 
are unaware that they can pass variables directly to the renderer. This practice removes the need in many cases 
to define multiple instance variables, and because the variables exist only in the renderer scope we do not 
violate encapsulation.

Although not specifically related to ViewContexts, the two practices complement each other well. 

See [this](https://rails-bestpractices.com/posts/2010/07/24/replace-instance-variable-with-local-variable/)
article for an overview of the concept. Although it deals specifically with partials, the concept applies to 
all `render` directives.

### Example

Calling `render` at the end of a controller action is the explicit way of doing what Rails does implicitly. 
We can pass any variables to the `locals` property as a hash.

**Controller**

```ruby
def show
 ...
 render locals: { designer: designer, cart: cart, ... }
end
```

Within the view context, this is available as `local_assigns`.

**View Context**

```ruby
def expected_earnings(designer:, cart:, **_rest)
 designer.default_pay_rate * cart.products.map do |p| 
  p.quantity * p.per_each
 end.sum
end
```

In this particular example, we've defined the method to destructure an incoming hash, allowing us to easily pass 
`local_assigns` directly rather than having to extract the values in the view. This is not required, 
but provides for less clutter in the template.

Provided the following template:

```erb
<span><%= humanized_money_with_symbol(expected_earnings(local_assigns)) %></span>
```

This markup will be rendered:

```html
<span>$2,600.00</span>
```

## More Information

This repo provides demonstrable code using custom ViewContexts. While not an exhaustive list, the following 
files provide some highlights for the specific use case:

- [app/controllers/concerns/view_context.rb](app/controllers/concerns/view_context.rb)
- [app/controllers/randoms_controller.rb](app/controllers/randoms_controller.rb)
- [app/view_contexts/randoms_view_context.rb](app/view_contexts/randoms_view_context.rb)

A demo is also available [here](https://rails-logical-view.herokuapp.com/).

> **What happened to all the other folders?**
>
> As the purpose of this project is demonstration rather than completeness, many extraneous components
> of typical Rails projects have been removed.  
