ActiveAdmin.register ReachDistanceSetting do
  permit_params :ranges, :is_active
  menu label: "Reach Distance"

  # We want only ONE settings row in DB (singleton-style)
  actions :all, except: [:destroy]

  index do
    selectable_column
    id_column
    column :is_active
    column("Ranges (km)") { |s| s.ranges_array.join(", ") }
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :is_active
      row("Ranges (km)") { |s| s.ranges_array.join(", ") }
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors

    f.inputs "Reach Distance Settings" do
      f.input :is_active, label: "Enable"

      f.input :ranges,
              label: "Distances (km) - comma separated",
              hint: "Example: 5,10,15,20,25 (only numbers, comma separated)",
              input_html: { placeholder: "5,10,15,20,25" }
    end

    f.actions
  end

  controller do
    # Enforce only one record:
    def new
      if ReachDistanceSetting.exists?
        redirect_to admin_reach_distance_settings_path,
                    alert: "Only one Reach Distance setting is allowed. Edit the existing one."
      else
        super
      end
    end

    def create
      if ReachDistanceSetting.exists?
        redirect_to admin_reach_distance_settings_path,
                    alert: "Only one Reach Distance setting is allowed. Edit the existing one."
      else
        super
      end
    end
  end
end
