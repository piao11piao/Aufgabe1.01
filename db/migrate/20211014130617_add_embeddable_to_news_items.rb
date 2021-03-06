class AddEmbeddableToNewsItems < ActiveRecord::Migration[6.0]
  def change
    add_column :news_items, :embeddable, :boolean, default: false
  end

  def data
    NewsItem.in_batches.update_all embeddable: true
  end
end
