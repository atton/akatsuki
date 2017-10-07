module ApplicationHelper
  def insert_alert
    content_tag('div') do
      notice_tag = notice.present? ? content_tag('div', notice, class: ['alert', 'alert-info'])   : nil
      alert_tag  = alert.present?  ? content_tag('div', alert,  class: ['alert', 'alert-danger']) : nil

      [notice_tag, alert_tag].join.html_safe
    end
  end

  def insert_model_alert model
    return if model.try(:errors).blank?

    content_tag('div') do
      model.errors.full_messages.map{|e| content_tag('div', e, class: ['alert', 'alert-danger'])}.join.html_safe
    end
  end

end
