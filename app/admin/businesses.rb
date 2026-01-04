ActiveAdmin.register Business do
  menu label: "Businesses"

  permit_params :user_id, :status, :name, :category, :year_established, :website, :about, products_services: []

  filter :status
  filter :category
  filter :user_id
  filter :created_at

  index do
    selectable_column
    id_column
    column :user_id
    column :name
    column :category
    column :status
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :user_id
      row :name
      row :category
      row :year_established
      row :website
      row :about
      row :products_services
      row :status
      row :created_at
      row :updated_at
    end
  end
end
