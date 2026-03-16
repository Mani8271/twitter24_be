ActiveAdmin.register Offer do
  menu label: "Offers", priority: 5

  permit_params :user_id, :title, :description, :offer_type,
                :latitude, :longitude, :address, :reach_distance,
                :valid_till, :tags, :disappearing_days

  # ─── SCOPES ───────────────────────────────────────────────────────────────
  scope :all, default: true
  scope("Local")  { |s| s.where(offer_type: "local")  }
  scope("Global") { |s| s.where(offer_type: "global") }
  scope("Active") { |s| s.where("valid_till IS NULL OR valid_till >= ?", Time.current) }
  scope("Expired") do |s|
    s.where("valid_till IS NOT NULL AND valid_till < ?", Time.current)
  end

  # ─── FILTERS ──────────────────────────────────────────────────────────────
  filter :title
  filter :offer_type, as: :select, collection: %w[local global]
  filter :valid_till
  filter :user_id
  filter :address
  filter :created_at

  # ─── BATCH ACTIONS ────────────────────────────────────────────────────────
  batch_action :destroy, confirm: "Delete selected offers? This cannot be undone." do |ids|
    Offer.where(id: ids).destroy_all
    redirect_to collection_path, notice: "#{ids.size} offer(s) deleted."
  end

  # ─── INDEX ────────────────────────────────────────────────────────────────
  index do
    selectable_column
    id_column

    column :title do |o|
      link_to o.title, admin_offer_path(o)
    end

    column "Posted By" do |o|
      o.user&.name || o.user&.phone_number
    end

    column :offer_type do |o|
      color = o.offer_type == "local" ? "#0369a1" : "#7c3aed"
      bg    = o.offer_type == "local" ? "#e0f2fe" : "#f3e8ff"
      span o.offer_type.capitalize, style: "
        display:inline-block; padding:2px 10px; border-radius:999px;
        font-size:12px; font-weight:700;
        color:#{color}; background:#{bg};
      "
    end

    column :address
    column :valid_till do |o|
      if o.valid_till.nil?
        span "No expiry", style: "color:#6b7280; font-size:12px;"
      elsif o.valid_till < Time.current
        span "Expired #{o.valid_till.strftime('%d %b %Y')}", style: "color:#dc2626; font-size:12px; font-weight:700;"
      else
        span "Until #{o.valid_till.strftime('%d %b %Y')}", style: "color:#16a34a; font-size:12px; font-weight:700;"
      end
    end

    column :created_at

    column "Media" do |o|
      o.media.attached? ? status_tag("Yes", class: "yes") : status_tag("No", class: "no")
    end

    column "Actions" do |o|
      link_to "View", admin_offer_path(o), class: "member_link"
    end
  end

  # ─── SHOW ─────────────────────────────────────────────────────────────────
  show do
    columns do
      column do
        panel "Offer Details" do
          attributes_table_for resource do
            row :id
            row :title
            row :description
            row(:offer_type) { |o| o.offer_type.capitalize }
            row :tags
            row(:valid_till) do |o|
              if o.valid_till.nil?
                "No expiry"
              elsif o.valid_till < Time.current
                span("Expired — #{o.valid_till.strftime('%d %b %Y %H:%M')}",
                     style: "color:#dc2626; font-weight:700;")
              else
                span("Active until #{o.valid_till.strftime('%d %b %Y %H:%M')}",
                     style: "color:#16a34a; font-weight:700;")
              end
            end
            row(:disappearing_days) { |o| o.disappearing_days ? "#{o.disappearing_days} days" : "—" }
            row :created_at
            row :updated_at
          end
        end

        panel "Links" do
          if resource.links.present?
            table_for resource.links do
              column("Button Name") { |l| l["button_name"] }
              column("URL")         { |l| link_to l["url"], l["url"], target: "_blank" }
            end
          else
            para "No links added."
          end
        end

        panel "Media" do
          if resource.media.attached?
            m = resource.media
            if m.content_type.start_with?("image/")
              image_tag url_for(m),
                        style: "max-width:100%; border-radius:10px; border:1px solid #e2e8f0;"
            else
              link_to "⬇ Download #{m.filename}",
                      rails_blob_path(m, disposition: "attachment"),
                      style: "font-weight:700; color:#7c3aed;"
            end
          else
            para "No media attached."
          end
        end
      end

      column do
        panel "Posted By" do
          if resource.user
            attributes_table_for resource.user do
              row :id
              row :name
              row :phone_number
              row :email
              row :account_type
            end
            div do
              link_to "View User →", admin_user_path(resource.user),
                      style: "font-weight:700; color:#7c3aed;"
            end
          else
            para "No user linked."
          end
        end

        panel "Location" do
          if resource.address.present? || resource.latitude.present?
            attributes_table_for resource do
              row :address
              row :latitude
              row :longitude
              row :reach_distance do |o|
                o.reach_distance.present? ? "#{o.reach_distance} km" : "—"
              end
            end
          else
            para "No location set."
          end
        end
      end
    end

    active_admin_comments
  end

  # ─── FORM ─────────────────────────────────────────────────────────────────
  form do |f|
    f.inputs "Offer Details" do
      f.input :title
      f.input :description
      f.input :offer_type, as: :select, collection: %w[local global]
      f.input :valid_till, as: :datetime_picker
      f.input :tags, hint: "Comma separated"
      f.input :disappearing_days
    end
    f.inputs "Location (required for local)" do
      f.input :address
      f.input :latitude
      f.input :longitude
      f.input :reach_distance, hint: "in km"
    end
    f.actions
  end
end
