ActiveAdmin.register GlobalFeed do
  menu label: "Feeds"

  # ✅ SCOPES (tabs on top)
  scope :all, default: true
  scope("Global") { |s| s.where(feed_type: "global") }
  scope("Local")  { |s| s.where(feed_type: "local") }

  # strong params for admin create/update
  permit_params :user_id, :feed_type, :title, :description, :category, :disappear_after,
                :latitude, :longitude, :address, :reach_distance, tags: [], links: []

  # Filters (right side)
  filter :feed_type, as: :select, collection: %w[global local]
  filter :category
  filter :user_id
  filter :title
  filter :created_at

  # Index page table
  index do
    selectable_column
    id_column
    column :user_id
    column :feed_type
    column :title
    column :category
    column :reach_distance
    column :created_at
    actions
  end

  # Show page
  show do
    attributes_table do
      row :id
      row :user_id
      row :feed_type
      row :title
      row :description
      row :category
      row :tags
      row :links
      row :disappear_after
      row :latitude
      row :longitude
      row :address
      row :reach_distance
      row :created_at
      row :updated_at
    end

    panel "Media" do
      if resource.media.attached?
        ul do
          resource.media.each do |m|
            li link_to(m.filename.to_s, rails_blob_path(m, disposition: "attachment"))
          end
        end
      else
        div "No media attached"
      end
    end
  end

  # Form page
  form do |f|
    f.inputs "Feed Details" do
      f.input :user_id
      f.input :feed_type, as: :select, collection: %w[global local]
      f.input :title
      f.input :description
      f.input :category
      f.input :disappear_after
      f.input :latitude
      f.input :longitude
      f.input :address
      f.input :reach_distance
      f.input :tags,
              as: :string,
              input_html: { value: (f.object.tags || []).join(",") },
              hint: "Comma separated"
    end
    f.actions
  end

  controller do
    # convert tags "a,b,c" -> ["a","b","c"]
    def create
      if params[:global_feed] && params[:global_feed][:tags].is_a?(String)
        params[:global_feed][:tags] = params[:global_feed][:tags].split(",").map(&:strip).reject(&:blank?)
      end
      super
    end

    def update
      if params[:global_feed] && params[:global_feed][:tags].is_a?(String)
        params[:global_feed][:tags] = params[:global_feed][:tags].split(",").map(&:strip).reject(&:blank?)
      end
      super
    end
  end
end
