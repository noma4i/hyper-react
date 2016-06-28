module React
  module Component
    # contains the name of all HTML tags, and the mechanism to register a component
    # class as a new tag
    module Tags
      HTML_TAGS = %w(a abbr address area article aside audio b base bdi bdo big blockquote body br
                     button canvas caption cite code col colgroup data datalist dd del details dfn
                     dialog div dl dt em embed fieldset figcaption figure footer form h1 h2 h3 h4 h5
                     h6 head header hr html i iframe img input ins kbd keygen label legend li link
                     main map mark menu menuitem meta meter nav noscript object ol optgroup option
                     output p param picture pre progress q rp rt ruby s samp script section select
                     small source span strong style sub summary sup table tbody td textarea tfoot th
                     thead time title tr track u ul var video wbr) +
                  # The SVG Tags
                  %w(circle clipPath defs ellipse g line linearGradient mask path pattern polygon polyline
                  radialGradient rect stop svg text tspan)

      # note: any tag can end in _as_node but this is deprecated

      # the present method is retained as a legacy behavior

      def present(component, *params, &children)
        React::RenderingContext.render(component, *params, &children)
      end

      def present_as_node(component, *params, &children)
        React::RenderingContext.build_only(component, *params, &children)
      end

      # define each predefined tag as an instance method

      HTML_TAGS.each do |tag|
        define_method(tag) do |*params, &children|
          if tag == 'p'
            if children || params.count == 0 || (params.count == 1 && params.first.is_a?(Hash))
              React::RenderingContext.render(tag, *params, &children)
            else
              Kernel.p(*params)
            end
          else
            React::RenderingContext.render(tag, *params, &children)
          end
        end
        alias_method tag.upcase, tag
        const_set tag.upcase, tag
        # handle deprecated _as_node style
        define_method("#{tag}_as_node") do |*params, &children|
          React::RenderingContext.build_only(tag, *params, &children)
        end
      end

      # use method_missing to look up component names in the form of "Foo(..)"
      # where there is no preceeding scope.

      def method_missing(name, *params, &children)
        if name =~ /_as_node$/
          # handle deprecated _as_node style
          component = find_component(name.gsub(/_as_node$/, ''))
          return React::RenderingContext.build_only(component, *params, &children) if component
        else
          component = find_component(name)
          return React::RenderingContext.render(component, *params, &children) if component
        end
        puts "about to super for #{name}"
        Object.method_missing(name, *params, &children)
      end

      # install methods with the same name as the component in the parent class/module
      # thus component names in the form Foo::Bar(...) will work

      class << self
        def included(component)
          _name, parent = find_name_and_parent(component)
          class << parent
            define_method _name do |*params, &children|
              React::RenderingContext.render(component, *params, &children)
            end
            # handle deprecated _as_node style
            define_method "#{_name}_as_node" do |*params, &children|
              React::RenderingContext.build_only(component, *params, &children)
            end
          end
        end

        private

        def find_name_and_parent(component)
          split_name = component.name && component.name.split('::')
          if split_name && split_name.length > 1
            [split_name.last, split_name.inject([Module]) { |a, e| a + [a.last.const_get(e)] }[-2]]
          end
        end
      end

      private

      def find_component(name)
        component = self.class.const_get(name) if self.class.const_defined? name
        if component
          unless component.method_defined? :render
            raise "#{name} does not appear to be a react component."
          end
          component
        end
      end
    end
  end
end