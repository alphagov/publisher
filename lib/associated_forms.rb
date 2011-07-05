module Formtastic #:nodoc:

  class SemanticFormBuilder < ActionView::Helpers::FormBuilder
    
    def association_name(class_name)
      @object.respond_to?("#{class_name}_attributes=") ? class_name : class_name.pluralize
    end

    def extract_option_or_class_name(hash, option, object)
      (hash.delete(option) || object.class.name.split('::').last.underscore)
    end
    
    #  Dynamically add and remove nested forms for a has_many relation.
    #
    #  Add a link to remove the associated partial
    #    # Example:
    #    <% semantic_form_for @post do |post| %>
    #      <%= post.input :title %>
    #      <% post.inputs :name => 'Authors', :id => 'authors' do %>
    #        <%= post.add_associated_link "+ Author", :authors, :partial => 'authors/add_author' %>
    #        <%= post.render_associated_form :authors, :partial => 'authors/add_author' %>
    #      <% end %>
    #    <% end %>
    #
    #    # app/views/authors/_add_author.html.erb
    #    <div class="author">
    #      <%= f.input :name %>
    #      <%= f.remove_link "Remove" %>
    #    </div>
    #
    #   # Output:
    #   <form ...>
    #     <li class="string"><input type='text' name='post[author][name]' id='post_author_name' /></li>
    #     <fieldset class="inputs" id="authors"><legend><span>Authors</span></legend><ol>
    #       <a href="#" onclick="if (typeof formtastic_next_author_id == 'undefined') ....return false;">+ Author</a>
    #       <div class="author">
    #         <li ...><label ...></label><input id="post_authors_name" maxlength="255"
    #           name="post[authors][name]" size="50" type="text" /></li>
    #         <input id="post_authors__delete" name="post[authors][_delete]" type="hidden" />
    #         <a href="#" onclick="$(this).parents('.author').hide(); $(this).prev(':input').val('1');; return false;">Remove</a>
    #      </div>
    #     </ol></fieldset>
    #   </form>
    #
    #  Opts:
    #
    #   * :selector, id of element that will disappear(.hide()), if no id as give, will use css class
    #       association.class.name last word in downcase #=> '.author'
    #     f.remove_link "Remove", :selector => '#my_own_element_id'
    #
    #   * :function, a funcion to execute before hide element and set _delete to 1
    #     f.remove_link "Remove", :function => "alert('Removing Author')"
    #
    #
    #   NOTE: remove_link must be put in the partial, not in main template
    #
    def remove_link(name, *args)
      options = args.extract_options!
      css_selector = options.delete(:selector) || ".#{@object.class.name.split("::").last.underscore}"

      function = options.delete(:function) || ""
      function    << ";$(this).parents('#{css_selector}').hide(); $(this).prev(':input').val('1');"

      out = hidden_field(:_destroy)
      out += template.link_to_function(name, function, *args.push(options))
    end
    
    def add_associated_jquery_template(association, opts = {})
      object = @object.send(association).build
      associated_name = extract_option_or_class_name(opts, :name, object)
      partial = opts.delete(:partial) || associated_name
      
      form = render_associated_form(object, :partial => partial)
      form.gsub!(/attributes_(\d+)/, 'attributes_{{index}}')
      form.gsub!(/\[(\d+)\]/, '[{{index}}]')
      
      "<script id='tmpl-#{association}' type='text/x-jquery-tmpl'>#{form}</script>".html_safe
    end
    
    # Render associated form
    #
    # Example:
    #
    #    <% semantic_form_for @post do |post| %>
    #      <%= post.input :title %>
    #      <% post.inputs :name => 'Authors', :id => 'authors' do %>
    #        <%= post.add_associated_link "+ Author", :authors, :partial => 'authors/add_author' %>
    #        <%= post.render_associated_form :authors, :partial => 'authors/add_author' %>
    #      <% end %>
    #    <% end %>
    #
    # Partial: app/views/authors/_add_author.html.erb
    #
    #    <% f.input :name %>
    #
    # Output:
    #
    #   <form ...>
    #     <li class="string"><input type='text' name='post[author][name]' id='post_author_name' /></li>
    #     <fieldset class="inputs" id="authors"><legend><span>Authors</span></legend><ol>
    #       <a href="#" onclick="if (typeof formtastic_next_author_id == 'undefined') ....return false;">+ Author</a>
    #       <li class="string required" ...><label ...></label><input id="post_authors_name" maxlength="255"
    #       name="post[authors][name]" size="50" type="text" value="Renan T. Fernandes" /></li>
    #     </ol></fieldset>
    #   </form>
    #
    # Opts:
    #   * :partial => Render a given partial, if no one is given, try to find a partial
    #                 with association name in the controller folder.
    #
    #   post.render_associated_form :authors, :partial => 'author'
    #   ^ try to render app/views/posts/_author.html.erb
    #
    #   post.render_associated_form :authors, :partial => 'authors/author'
    #   ^ try to render app/views/authors/_author.html.erb
    #
    # NOTE: Partial need to use 'f' as formtastic reference. Example:
    #
    #       <%= f.input :name %> #=> render author name association
    #
    #   * :new    => make N empty partials if it is a new record. Example:
    #
    #   post.render_associated_form :authors, :new => 2
    #   ^ make 2 empty authors partials
    #
    #   * :edit   => show only X partial if is editing a record. Example:
    #
    #   post.render_associated_form :authors, :edit => 3
    #   ^ if record have 1 author, make 2 new empty partials
    #   NOTE: :edit not conflicts with :new; :new is for new records only
    #
    #   * :new_in_edit  => show X new partial if is editing a record. Example:
    #
    #   post.render_associated_form :authors, :new_in_edit => 2
    #   ^ make more 2 new partial for record
    #   NOTE: this option is ignored if :edit is seted
    #
    #   Example:
    #
    #   post.render_associated_form :authors, :edit => 2, :new_in_edit => 100
    #   ^ if record have 1 author, make more one partial
    #
    def render_associated_form(associated, opts = {})
      associated = @object.send(associated.to_s) if associated.is_a? Symbol
      associated = associated.is_a?(Array) ? associated : [associated] # preserve association proxy if this is one

      opts.symbolize_keys!

      (opts[:new] - associated.select(&:new_record?).length).times  { associated.build } if opts[:new]  and @object.new_record? == true
      if opts[:edit] and @object.new_record? == false
        (opts[:edit] - associated.count).times { associated.build }
      elsif opts[:new_in_edit] and @object.new_record? == false
        opts[:new_in_edit].times { associated.build }
      end
      
      opts[:locals] ||= {}
      opts[:render] ||= {}

      unless associated.empty?
        name = extract_option_or_class_name(opts, :name, associated.first)
        partial = opts[:partial] || name
        local_assign_name = partial.split('/').last.split('.').first

        index = -1
        index_variable_name = "#{partial}_counter".to_sym
        output = associated.map do |element|
          fields_for(association_name(name), element, (opts[:fields_for] || {}).merge(:name => name)) do |f|
            local_assignments = {index_variable_name => index += 1, local_assign_name.to_sym => element, :f => f}.merge(opts[:locals])
            template.render({:partial => "#{partial}", :locals => local_assignments}.merge(opts[:render]))
          end
        end
        output.join
      end
    end
  end
end