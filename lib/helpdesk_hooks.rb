class HelpdeskHooks < Redmine::Hook::Listener

  # render partial for 'Send mail to supportclient'
  def view_issues_edit_notes_bottom(context={})
    i = Issue.find(context[:issue].id)
    c = CustomField.find_by_name('owner-email')
    owner_email = i.custom_value_for(c).try(:value)
    return if owner_email.blank?
    p = i.project
    s = CustomField.find_by_name('helpdesk-send-to-owner-default')
    send_to_owner_default = p.custom_value_for(s).try(:value) if p.present? && s.present?

    lookup_context = ActionView::LookupContext.new(File.dirname(__FILE__) + '/../app/views/')
    context = ActionView::Base.with_empty_template_cache.new(lookup_context, {}, nil)
    renderer = ActionView::Renderer.new(lookup_context)
    renderer.render(context,
      :partial => "issue_edit",
      :locals => {
        :email => owner_email,
        :send_to_owner_default => (send_to_owner_default.present? && send_to_owner_default || false)
      }
    )
  end
  
  # fetch 'send_to_owner' param and set the value into journal.send_to_owner
  def controller_issues_edit_before_save(context={})
    send_to_owner = (context[:params]['send_to_owner'] == "true")
    context[:journal].send_to_owner = send_to_owner
  end
  
  # add a history note on the journal
  def view_issues_history_journal_bottom(context={})
    return if (context[:journal].nil? || context[:journal].notes.nil? || context[:journal].notes.length == 0)
    return unless context[:journal].send_to_owner == true
    i = Issue.find(context[:journal].journalized_id)
    c = CustomField.find_by_name('owner-email')
    owner_email = i.custom_value_for(c).try(:value)
    return if owner_email.blank?
    lookup_context = ActionView::LookupContext.new(File.dirname(__FILE__) + '/../app/views/')
    context = ActionView::Base.with_empty_template_cache.new(lookup_context, {}, nil)
    renderer = ActionView::Renderer.new(lookup_context)
    renderer.render(context,
                    :partial => "issue_history",
                    :locals => {:email => owner_email}
    )
  end
  
end
