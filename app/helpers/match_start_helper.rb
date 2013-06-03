module MatchStartHelper
  def grouped_options_for_select_with_optgroup_options(
    grouped_options, selected_key = nil, prompt = nil
  )
    body = ''
    body << content_tag(:option, prompt, { :value => "" }, true) if prompt

    grouped_options.each do |group|
      optgroup = group.first
      user_options = group.last

      optgroup_label = optgroup
      optgroup_options = if optgroup.length > 1
        optgroup_label = optgroup.first
        optgroup.last
      else
        {}
      end

      body << (
        content_tag(
          :optgroup,
          options_for_select(
            user_options,
            selected_key
          ),
          optgroup_options.merge(:label => optgroup_label)
        )
      )
    end

    body.html_safe
  end
end
