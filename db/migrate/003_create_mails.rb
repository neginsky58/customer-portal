class CreateMails < ActiveRecord::Migration
  def self.up
    create_table :mails do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :mails
  end
end
