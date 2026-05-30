ActiveAdmin.register Business do
  menu label: "Businesses", priority: 2

  permit_params :user_id, :status, :name, :category, :year_established,
                :website, :about, :rejection_reason, products_services: []

  # ─── SCOPES ───────────────────────────────────────────────────────────────
  scope :all, default: true
  scope("Pending Review") { |s| s.where(status: "submitted") }
  scope("Approved")       { |s| s.where(status: "approved") }
  scope("Rejected")       { |s| s.where(status: "rejected") }
  scope("Draft")          { |s| s.where(status: "draft") }

  # ─── FILTERS ──────────────────────────────────────────────────────────────
  filter :name
  filter :category
  filter :status, as: :select, collection: %w[draft submitted approved rejected]
  filter :created_at
  filter :user_id

  # ─── BATCH ACTIONS ────────────────────────────────────────────────────────
  batch_action :approve, confirm: "Approve selected businesses?" do |ids|
    ActiveRecord::Base.transaction do
      Business.where(id: ids).each { |b| b.update!(status: "approved") }
    end
    redirect_to collection_path, notice: "#{ids.size} business(es) approved."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to collection_path, alert: "Batch approve failed: #{e.message}"
  end

  batch_action :reject,
               form: { rejection_reason: :textarea } do |ids, inputs|
    reason = inputs[:rejection_reason].presence
    ActiveRecord::Base.transaction do
      Business.where(id: ids).each do |b|
        b.update!(status: "rejected", rejection_reason: reason)
        OnboardingMailer.rejection_notification(b.user, b).deliver_now rescue nil
      end
    end
    redirect_to collection_path, notice: "#{ids.size} business(es) rejected. Owners notified."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to collection_path, alert: "Batch reject failed: #{e.message}"
  end

  # ─── MEMBER ACTIONS ───────────────────────────────────────────────────────
  member_action :approve, method: :put do
    resource.update!(status: "approved", rejection_reason: nil)
    redirect_to admin_business_path(resource),
                notice: "✅ #{resource.name} has been approved."
  end

  member_action :reject, method: :get do
    @business = resource
    render :reject
  end

  member_action :do_reject, method: :post do
    reason = params[:rejection_reason].presence
    resource.update!(status: "rejected", rejection_reason: reason)
    OnboardingMailer.rejection_notification(resource.user, resource).deliver_now
    redirect_to admin_business_path(resource),
                notice: "❌ #{resource.name} has been rejected. Owner notified by email."
  end

  # ─── INDEX ────────────────────────────────────────────────────────────────
  index do
    selectable_column
    id_column
    column :name
    column :category
    column("Owner")  { |b| b.user&.name }
    column("Phone")  { |b| b.business_contact&.contact_phone }
    column("City")   { |b| b.business_location&.city }

    column :status do |b|
      text_color = { "approved" => "#16a34a", "submitted" => "#d97706", "draft" => "#6b7280", "rejected" => "#dc2626" }
      bg_color   = { "approved" => "#dcfce7", "submitted" => "#fef3c7", "draft" => "#f1f5f9",  "rejected" => "#fee2e2" }
      span b.status.to_s.capitalize, style: "
        display:inline-block; padding:2px 10px; border-radius:999px;
        font-size:12px; font-weight:700;
        color:#{text_color[b.status]}; background:#{bg_color[b.status]};
        border:1px solid #{text_color[b.status]}33;
      "
    end

    column :created_at

    column "Actions" do |b|
      links = [ link_to("View", admin_business_path(b), class: "member_link") ]
      if b.status == "submitted"
        links << link_to("✅ Approve", approve_admin_business_path(b),
                         method: :put, class: "member_link",
                         style: "color:#16a34a; font-weight:700;",
                         data: { confirm: "Approve #{b.name}?" })
        links << link_to("❌ Reject", reject_admin_business_path(b),
                         class: "member_link",
                         style: "color:#dc2626; font-weight:700;")
      elsif b.status == "approved"
        links << link_to("⚠️ Revoke", reject_admin_business_path(b),
                         class: "member_link",
                         style: "color:#dc2626; font-weight:700;")
      end
      safe_join(links, " | ")
    end
  end

  # ─── SHOW ─────────────────────────────────────────────────────────────────
  show do
    panel "Status & Actions" do
      text_color = { "approved" => "#16a34a", "submitted" => "#d97706", "draft" => "#6b7280", "rejected" => "#dc2626" }
      bg_color   = { "approved" => "#dcfce7", "submitted" => "#fef3c7", "draft" => "#f1f5f9",  "rejected" => "#fee2e2" }
      div style: "display:flex; align-items:center; gap:12px; padding:8px 0; flex-wrap:wrap;" do
        span resource.status.to_s.upcase, style: "
          padding:6px 20px; border-radius:999px; font-weight:800; font-size:14px;
          color:#{text_color[resource.status]};
          background:#{bg_color[resource.status]};
          border:1px solid #{text_color[resource.status]}44;
        "
        if resource.status == "submitted"
          link_to "✅ Approve", approve_admin_business_path(resource),
                  method: :put, class: "button",
                  style: "background:#16a34a;color:#fff;padding:8px 20px;border-radius:8px;font-weight:700;text-decoration:none;",
                  data: { confirm: "Approve #{resource.name}?" }
          link_to "❌ Reject", reject_admin_business_path(resource),
                  class: "button",
                  style: "background:#dc2626;color:#fff;padding:8px 20px;border-radius:8px;font-weight:700;text-decoration:none;"
        elsif resource.status == "approved"
          link_to "⚠️ Revoke Approval", reject_admin_business_path(resource),
                  class: "button",
                  style: "background:#dc2626;color:#fff;padding:8px 20px;border-radius:8px;font-weight:700;text-decoration:none;"
        end
      end

      if resource.status == "rejected" && resource.rejection_reason.present?
        div style: "margin-top:12px; padding:14px 18px; background:#fee2e2; border:1px solid #fca5a5; border-radius:8px;" do
          para "Rejection Reason:", style: "font-weight:700; font-size:13px; color:#dc2626; margin:0 0 6px;"
          para resource.rejection_reason, style: "font-size:14px; color:#991b1b; margin:0; white-space:pre-wrap;"
        end
      end
    end

    columns do
      column do
        panel "Business Details" do
          attributes_table_for resource do
            row :id; row :name; row :category
            row :year_established; row :website; row :about
            row("Services") { |b| (b.products_services || []).join(", ") }
            row :status; row :created_at
          end
        end

        panel "Owner / User" do
          if resource.user
            attributes_table_for resource.user do
              row :id; row :name; row :phone_number
              row :email; row :account_type; row :created_at
            end
          else
            para "No user linked."
          end
        end
      end

      column do
        panel "Contact Information" do
          if resource.business_contact
            attributes_table_for resource.business_contact do
              row :contact_person_name; row :contact_phone; row :contact_email
              row :owner_name; row :owner_phone; row :owner_email
            end
          else
            para "No contact info yet."
          end
        end

        panel "Location" do
          if resource.business_location
            attributes_table_for resource.business_location do
              row :map_address; row :address_line1; row :address_line2
              row :city; row :state; row :pin_code
              row :latitude; row :longitude
            end
          else
            para "No location info yet."
          end
        end

        panel "Business Hours" do
          days = %w[Sun Mon Tue Wed Thu Fri Sat]
          hours = resource.business_hours.order(:day_of_week)
          if hours.any?
            table_for hours do
              column("Day")    { |h| days[h.day_of_week] }
              column("Open?")  { |h| h.is_open ? "✅ Open" : "❌ Closed" }
              column("Opens")  { |h| h.is_open ? h.opens_at&.strftime("%I:%M %p") : "-" }
              column("Closes") { |h| h.is_open ? h.closes_at&.strftime("%I:%M %p") : "-" }
            end
          else
            para "No hours set."
          end
        end
      end
    end

    panel "Documents" do
      if resource.business_document
        attributes_table_for resource.business_document do
          row("GSTIN") { |d| d.has_gstin ? d.gstin : "Not provided" }
          row("PAN")   { |d| d.has_pan   ? d.pan   : "Not provided" }
          row("FSSAI") { |d| d.has_fssai ? d.fssai : "Not provided" }
        end
      else
        para "No documents uploaded.", style: "color:#9ca3af;"
      end
    end

    panel "Images" do
      has_pp   = resource.profile_picture.attached?
      has_shop = resource.shop_images.attached?

      # ── Summary bar ─────────────────────────────────────────────
      div style: "display:flex;align-items:center;gap:10px;margin-bottom:18px;padding:10px 14px;background:#f8fafc;border-radius:8px;border:1px solid #e2e8f0;" do
        span style: "font-size:13px;font-weight:700;color:#374151;" do
          text_node "Image Summary:"
        end
        if has_pp
          span style: "background:#e0e7ff;color:#4338ca;font-size:11px;font-weight:700;border-radius:999px;padding:3px 10px;" do
            text_node "1 Profile Picture"
          end
        end
        if has_shop
          count = resource.shop_images.count
          span style: "background:#dcfce7;color:#15803d;font-size:11px;font-weight:700;border-radius:999px;padding:3px 10px;" do
            text_node "#{count} Gallery #{count == 1 ? 'Image' : 'Images'}"
          end
        end
        unless has_pp || has_shop
          span style: "color:#9ca3af;font-size:13px;" do
            text_node "No images uploaded"
          end
        end
      end

      # ── Placeholder when no images ───────────────────────────────
      unless has_pp || has_shop
        div style: "display:flex;flex-direction:column;align-items:center;justify-content:center;padding:52px 24px;background:#f8fafc;border-radius:12px;border:2px dashed #cbd5e1;text-align:center;" do
          div style: "font-size:52px;line-height:1;margin-bottom:14px;" do
            text_node "🖼️"
          end
          div style: "font-size:15px;font-weight:700;color:#475569;margin-bottom:6px;" do
            text_node "No images uploaded yet"
          end
          div style: "font-size:13px;color:#94a3b8;" do
            text_node "The business owner has not uploaded a profile picture or shop images during onboarding."
          end
        end
      end

      # ── Profile Picture / Business Logo ─────────────────────────
      if has_pp
        div style: "margin-bottom:28px;" do
          div style: "display:flex;align-items:center;gap:10px;margin-bottom:14px;padding-bottom:10px;border-bottom:2px solid #e2e8f0;" do
            div style: "font-size:11px;font-weight:800;color:#475569;text-transform:uppercase;letter-spacing:1px;" do
              text_node "Business Logo / Profile Picture"
            end
            span style: "background:#e0e7ff;color:#4338ca;font-size:11px;font-weight:700;border-radius:999px;padding:2px 10px;" do
              text_node "1 image"
            end
          end
          div style: "display:flex;gap:20px;align-items:flex-start;flex-wrap:wrap;" do
            # Image thumbnail
            div style: "flex-shrink:0;border-radius:14px;overflow:hidden;border:3px solid #818cf8;width:180px;background:#f1f5f9;" do
              link_to image_tag(url_for(resource.profile_picture),
                                alt: "Profile Picture",
                                style: "width:180px;height:180px;object-fit:cover;display:block;"),
                      url_for(resource.profile_picture),
                      target: "_blank", rel: "noopener noreferrer",
                      style: "display:block;"
              div style: "padding:8px 12px;background:#f8fafc;border-top:1px solid #e2e8f0;" do
                div style: "font-size:10px;color:#94a3b8;word-break:break-all;margin-bottom:2px;" do
                  text_node resource.profile_picture.blob.filename.to_s
                end
                div style: "font-size:10px;color:#94a3b8;" do
                  text_node number_to_human_size(resource.profile_picture.blob.byte_size)
                end
              end
            end
            # Metadata
            div style: "color:#64748b;font-size:13px;padding-top:4px;" do
              para style: "margin:0 0 8px;" do
                strong "Content type: "
                text_node resource.profile_picture.blob.content_type
              end
              para style: "margin:0 0 8px;" do
                strong "Size: "
                text_node number_to_human_size(resource.profile_picture.blob.byte_size)
              end
              para style: "margin:0 0 16px;" do
                strong "Uploaded: "
                text_node resource.profile_picture.blob.created_at.strftime("%b %d, %Y at %I:%M %p")
              end
              link_to "🔍 View Full Size",
                      url_for(resource.profile_picture),
                      target: "_blank", rel: "noopener noreferrer",
                      style: "display:inline-block;padding:7px 16px;background:#e0e7ff;color:#4338ca;border-radius:7px;font-size:12px;font-weight:700;text-decoration:none;"
            end
          end
        end
      end

      # ── Shop / Gallery Images ────────────────────────────────────
      if has_shop
        shop_images = resource.shop_images_attachments.includes(:blob)
        div do
          div style: "display:flex;align-items:center;gap:10px;margin-bottom:14px;padding-bottom:10px;border-bottom:2px solid #e2e8f0;" do
            div style: "font-size:11px;font-weight:800;color:#475569;text-transform:uppercase;letter-spacing:1px;" do
              text_node "Shop / Gallery Images"
            end
            count = shop_images.count
            span style: "background:#dcfce7;color:#15803d;font-size:11px;font-weight:700;border-radius:999px;padding:2px 10px;" do
              text_node "#{count} #{count == 1 ? 'image' : 'images'}"
            end
          end
          div style: "display:grid;grid-template-columns:repeat(auto-fill,minmax(175px,1fr));gap:16px;" do
            shop_images.each_with_index do |img, i|
              div style: "border-radius:12px;overflow:hidden;border:2px solid #e2e8f0;background:#f8fafc;" do
                link_to image_tag(url_for(img),
                                  alt: "Shop Image #{i + 1}",
                                  style: "width:100%;height:155px;object-fit:cover;display:block;"),
                        url_for(img),
                        target: "_blank", rel: "noopener noreferrer",
                        title: "Click to view #{img.blob.filename} at full size",
                        style: "display:block;"
                div style: "padding:8px 10px;background:#f8fafc;border-top:1px solid #e2e8f0;" do
                  div style: "font-size:11px;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:0.3px;margin-bottom:4px;" do
                    text_node "Image #{i + 1}"
                  end
                  div style: "font-size:10px;color:#94a3b8;word-break:break-all;margin-bottom:2px;" do
                    text_node img.blob.filename.to_s
                  end
                  div style: "display:flex;align-items:center;justify-content:space-between;" do
                    span style: "font-size:10px;color:#94a3b8;" do
                      text_node number_to_human_size(img.blob.byte_size)
                    end
                    link_to "↗", url_for(img),
                            target: "_blank", rel: "noopener noreferrer",
                            title: "Open full size",
                            style: "font-size:13px;color:#818cf8;text-decoration:none;font-weight:700;"
                  end
                end
              end
            end
          end
        end
      end
    end

    active_admin_comments
  end

  # ─── FORM ─────────────────────────────────────────────────────────────────
  form do |f|
    f.inputs "Business Details" do
      f.input :name; f.input :category
      f.input :year_established; f.input :website; f.input :about
      f.input :status, as: :select,
              collection: [["Draft","draft"],["Submitted","submitted"],["Approved","approved"],["Rejected","rejected"]]
    end
    f.actions
  end
end
