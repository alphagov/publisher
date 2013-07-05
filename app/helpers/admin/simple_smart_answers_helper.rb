module Admin::SimpleSmartAnswersHelper
  def option_controls(option)
    error_css = option.object.errors.empty? ? '' : ' error'
    next_node_error = (if option.object.errors.has_key?(:next_node)
      %Q(<span class="help-inline">#{option.object.errors[:next_node].join(', ')}</span>)
    else
      ''
    end)
    %Q(<div class="control-group#{error_css}">
         <input type="radio" disabled>
         #{option.input :label, :label => false,
            :input_html => { :placeholder => "Label", :class => "option-label" } }
         <i class="icon-arrow-right"></i>
         #{option.input :next_node, :as => :hidden, :input_html => { :class => "next-node-id" } }
         <select class="required next-node-list" name="next-node-list">
           <option value="" class="default">Select a node..</option>
           <optgroup label="Questions" class="question-list"></optgroup>
           <optgroup label="Outcomes" class="outcome-list"></optgroup>
         </select>
         #{option.link_to_remove "<i class=\"icon-remove\"></i> Remove option".html_safe, 
            :class => "btn btn-link btn-small remove-option" }
         #{next_node_error} 
       </div>).html_safe
  end
end
