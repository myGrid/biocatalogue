ActiveRecord::Schema.define(:version => 0) do
  create_table :books, :force => true do |t|
    t.string :title
    t.string :author_name
    t.string :isbn
    t.integer :pub_year
    t.text :summary
  end
  
  create_table :chapters, :force => true do |t|
    t.integer :chapter_number
    t.string :title
    t.text :summary
    t.integer :book_id
  end
end