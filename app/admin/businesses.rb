ActiveAdmin.register Business do
  menu label: "Businesses", priority: 2

  permit_params :user_id, :status, :name, :category, :year_established,
                :website, :about, products_services: []

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
    Business.where(id: ids).each { |b| b.update!(status: "approved") }
    redirect_to collection_path, notice: "#{ids.size} business(es) approved."
  end

  batch_action :reject, confirm: "Reject selected businesses? Owners will be notified by email." do |ids|
    Business.where(id: ids).each do |b|
      b.update!(status: "rejected")
      OnboardingMailer.rejection_notification(b.user, b).deliver_now rescue nil
    end
    redirect_to collection_path, notice: "#{ids.size} business(es) rejected. Owners notified."
  end

  # ─── MEMBER ACTIONS ───────────────────────────────────────────────────────
  member_action :approve, method: :put do
    resource.update!(status: "approved")
    redirect_to admin_business_path(resource),
                notice: "✅ #{resource.name} has been approved."
  end

  member_action :reject, method: :put do
    resource.update!(status: "rejected")
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
                         method: :put, class: "member_link",
                         style: "color:#dc2626; font-weight:700;",
                         data: { confirm: "Reject #{b.name}? Owner will be notified by email." })
      elsif b.status == "approved"
        links << link_to("⚠️ Revoke", reject_admin_business_path(b),
                         method: :put, class: "member_link",
                         style: "color:#dc2626; font-weight:700;",
                         data: { confirm: "Revoke approval for #{b.name}?" })
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
                  method: :put, class: "button",
                  style: "background:#dc2626;color:#fff;padding:8px 20px;border-radius:8px;font-weight:700;text-decoration:none;",
                  data: { confirm: "Reject #{resource.name}? Owner will be notified by email." }
        elsif resource.status == "approved"
          link_to "⚠️ Revoke Approval", reject_admin_business_path(resource),
                  method: :put, class: "button",
                  style: "background:#dc2626;color:#fff;padding:8px 20px;border-radius:8px;font-weight:700;text-decoration:none;",
                  data: { confirm: "Revoke approval for #{resource.name}?" }
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
      div style: "display:flex; flex-wrap:wrap; gap:16px; padding:8px 0;" do
        if resource.profile_picture.attached?
          div style: "text-align:center;" do
            para "Profile Picture", style: "font-weight:700;margin-bottom:6px;font-size:12px;color:#6b7280;text-transform:uppercase;"
            image_tag url_for(resource.profile_picture),
                      style: "width:140px;height:140px;object-fit:cover;border-radius:12px;border:2px solid #e2e8f0;display:block;"
          end
        end
        if resource.shop_images.attached?
          resource.shop_images.each_with_index do |img, i|
            div style: "text-align:center;" do
              para "Shop Image #{i + 1}", style: "font-weight:700;margin-bottom:6px;font-size:12px;color:#6b7280;text-transform:uppercase;"
              image_tag url_for(img),
                        style: "width:140px;height:140px;object-fit:cover;border-radius:12px;border:2px solid #e2e8f0;display:block;"
            end
          end
        end
        unless resource.profile_picture.attached? || resource.shop_images.attached?
          para "No images uploaded yet.", style: "color:#9ca3af;"
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
