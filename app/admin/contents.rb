ActiveAdmin.register Content do
  permit_params :title, :subtitle, :content

  index do
    selectable_column
    id_column
    column :title
    column :subtitle
    column :created_at
    actions
  end

  filter :title
  filter :created_at

  form do |f|
    f.inputs "Content Details" do
      f.input :title
      f.input :subtitle
      f.input :content, as: :text
      # If using ActionText / Trix editor, use:
      # f.rich_text_area :content
    end
    f.actions
  end

  show do
    attributes_table do
      row :title
      row :subtitle
      row(:content) { |c| simple_format c.content }
      row :created_at
      row :updated_at
    end
  end
end
