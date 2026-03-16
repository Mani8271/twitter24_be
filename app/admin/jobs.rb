ActiveAdmin.register Job do
  menu label: "Jobs", priority: 4

  permit_params :user_id, :job_title, :description, :job_type, :post_type,
                :experience, :salary, :working_hours, :skills_required,
                :location_name, :latitude, :longitude, :reach_distance,
                :tags, :disappearing_days

  # ─── SCOPES ───────────────────────────────────────────────────────────────
  scope :all, default: true
  scope("Local")  { |s| s.where(post_type: "local")  }
  scope("Global") { |s| s.where(post_type: "global") }
  scope("Full-Time")  { |s| s.where(job_type: "full_time")  }
  scope("Part-Time")  { |s| s.where(job_type: "part_time")  }
  scope("Internship") { |s| s.where(job_type: "internship") }
  scope("Contract")   { |s| s.where(job_type: "contract")   }
  scope("Freelance")  { |s| s.where(job_type: "freelance")  }

  # ─── FILTERS ──────────────────────────────────────────────────────────────
  filter :job_title
  filter :job_type, as: :select,
         collection: [["Full-Time", "full_time"], ["Part-Time", "part_time"],
                      ["Internship", "internship"], ["Contract", "contract"], ["Freelance", "freelance"]]
  filter :post_type, as: :select, collection: %w[local global]
  filter :experience
  filter :salary
  filter :location_name
  filter :user_id
  filter :created_at

  # ─── BATCH ACTIONS ────────────────────────────────────────────────────────
  batch_action :destroy, confirm: "Delete selected jobs? This cannot be undone." do |ids|
    Job.where(id: ids).destroy_all
    redirect_to collection_path, notice: "#{ids.size} job(s) deleted."
  end

  # ─── INDEX ────────────────────────────────────────────────────────────────
  index do
    selectable_column
    id_column

    column :job_title do |j|
      link_to j.job_title, admin_job_path(j)
    end

    column "Posted By" do |j|
      j.user&.name || j.user&.phone_number
    end

    column :job_type do |j|
      j.job_type&.gsub("_", " ")&.titlecase
    end

    column :post_type do |j|
      color = j.post_type == "local" ? "#0369a1" : "#7c3aed"
      bg    = j.post_type == "local" ? "#e0f2fe" : "#f3e8ff"
      span j.post_type.capitalize, style: "
        display:inline-block; padding:2px 10px; border-radius:999px;
        font-size:12px; font-weight:700;
        color:#{color}; background:#{bg};
      "
    end

    column :experience
    column :salary do |j|
      j.salary ? "₹#{j.salary.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} /mo" : "—"
    end
    column :location_name
    column :created_at

    column "Actions" do |j|
      link_to "View", admin_job_path(j), class: "member_link"
    end
  end

  # ─── SHOW ─────────────────────────────────────────────────────────────────
  show do
    columns do
      column do
        panel "Job Details" do
          attributes_table_for resource do
            row :id
            row :job_title
            row(:job_type)  { |j| j.job_type&.gsub("_", " ")&.titlecase }
            row(:post_type) { |j| j.post_type&.capitalize }
            row :experience
            row(:salary)    { |j| j.salary ? "₹#{j.salary.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} / month" : "—" }
            row :working_hours
            row :skills_required
            row :description
            row :tags
            row(:disappearing_days) { |j| j.disappearing_days ? "#{j.disappearing_days} days" : "—" }
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
          if resource.location_name.present? || resource.latitude.present?
            attributes_table_for resource do
              row :location_name
              row :latitude
              row :longitude
              row :reach_distance do |j|
                j.reach_distance.present? ? "#{j.reach_distance} km" : "—"
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
    f.inputs "Job Details" do
      f.input :job_title
      f.input :job_type, as: :select,
              collection: [["Full-Time", "full_time"], ["Part-Time", "part_time"],
                           ["Internship", "internship"], ["Contract", "contract"], ["Freelance", "freelance"]]
      f.input :post_type, as: :select, collection: %w[local global]
      f.input :experience, as: :select,
              collection: ["Fresher", "6 months", "1 year", "2 years", "3 years", "4 years", "5+ years"]
      f.input :salary
      f.input :working_hours
      f.input :skills_required
      f.input :description
      f.input :tags, hint: "Comma separated"
      f.input :disappearing_days
    end
    f.inputs "Location" do
      f.input :location_name
      f.input :latitude
      f.input :longitude
      f.input :reach_distance, hint: "in km (only for local jobs)"
    end
    f.actions
  end
end
