ActiveAdmin.register Content do
  permit_params :title, :subtitle, :content

  index do
    selectable_column
    id_column
    column :title
    column :subtitle
    column :updated_at
    actions
  end

  filter :title
  filter :created_at

  form do |f|
    f.inputs "Content Details" do
      f.input :title,
              hint: "Use 'terms_and_conditions' or 'privacy_policy' as the key title"
      f.input :subtitle
      f.input :content, as: :text,
              input_html: {
                id: "html_content_editor",
                rows: 30,
                style: "font-family: monospace; font-size: 13px;"
              },
              hint: "Enter raw HTML. The CodeMirror editor below will activate automatically."
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

    panel "HTML Preview" do
      div do
        raw resource.content.to_s
      end
    end
  end
end
