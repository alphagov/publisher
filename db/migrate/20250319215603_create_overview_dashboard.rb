class CreateOverviewDashboard < ActiveRecord::Migration[7.1]
  def change
    create_table :overview_dashboards do |t|
      t.string :dashboard_type      
      t.string :result_group        
      t.integer :count              
      t.integer :draft              
      t.integer :amends_needed      
      t.integer :in_review          
      t.integer :ready              
      t.integer :fact_check_received
      t.integer :fact_check         
      t.integer :published          
      t.integer :archived
      t.timestamps
    end
  end
end
