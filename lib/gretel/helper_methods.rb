module Gretel
  module HelperMethods
    include ActionView::Helpers::UrlHelper
    def controller # hack because ActionView::Helpers::UrlHelper needs a controller method
    end
    
    def self.included(base)
      base.send :helper_method, :breadcrumb_for, :breadcrumb
    end
    
    def breadcrumb(*args)
      options = args.extract_options!
      name, object = args[0], args[1]
      
      if name
        @_breadcrumb_name = name
        @_breadcrumb_object = object
      else
        if @_breadcrumb_name
          crumb = breadcrumb_for(@_breadcrumb_name, @_breadcrumb_object, options)
        elsif options[:show_root_alone]
          crumb = breadcrumb_for(:root, options)
        end
      end
      
      if crumb && options[:pretext]
        crumb = options[:pretext].html_safe + " " + crumb
      end
      
      crumb
    end
    
    def breadcrumb_for(*args)
      options = args.extract_options!
      link_last = options[:link_last]
      options[:link_last] = true
      separator = (options[:separator] || "&gt;").html_safe

      name, object = args[0], args[1]
      
      crumb = Crumbs.get_crumb(name, object)
      out = [crumb_link_if(link_last, crumb, options)]

      while parent = crumb.parent
        last_parent = parent.name
        crumb = Crumbs.get_crumb(parent.name, parent.object)
        out.unshift(crumb_link(crumb, options))
      end
      
      # TODO: Refactor this
      if options[:autoroot] && name != :root && last_parent != :root
        crumb = Crumbs.get_crumb(:root)
        out.unshift(crumb_link(crumb, options))
      end

      if options[:microformat]
        out = out.map {|breadcrumb_link| "<span itemscope itemtype=\"http://data-vocabulary.org/Breadcrumb\">#{breadcrumb_link}</span>"}
      end
      
      out.join(" #{separator} ").html_safe
    end

    def crumb_link_if(condition, crumb, options = {})
      if options[:microformat]
        crumb_link_text = content_tag(:span, crumb.link.text, :itemprop => 'title')
        link_options = crumb.link.options.reverse_merge({:itemprop => 'url'})
      else
        crumb_link_text = crumb.link.text
        link_options = crumb.link.options
      end
      
      output = link_to_if(condition, crumb_link_text, crumb.link.url, link_options)
      output
    end

    def crumb_link(crumb, options = {})
      crumb_link_if(true, crumb, options)
    end
  end
end
