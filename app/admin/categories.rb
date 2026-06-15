ActiveAdmin.register Category do
  permit_params :name, :emoji, :is_active, :priority

  index do
    selectable_column
    id_column
    column :name
    column :emoji
    column :priority
    column :is_active
    column :created_at
    actions
  end

  filter :name
  filter :is_active
  filter :created_at

  form do |f|
    f.inputs do
      f.input :name
      f.input :emoji
      f.input :priority
      f.input :is_active
    end
    f.actions
  end
end
