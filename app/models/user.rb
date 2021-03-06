class User < ActiveRecord::Base
  validates :name, :email, :phone, presence: true
  validates :email, format: { with: /([0-9a-zA-Z]+[-._+&amp;])*[0-9a-zA-Z]+@([-0-9a-zA-Z]+[.])+[a-zA-Z]{2,6}/ }
  validates :email, uniqueness: true
  validates :phone, format: { with: /\([\d]{2}\)\s[\d]{8,9}/ }
  after_create :mailchimp_sync
  after_create { UserMailer.welcome(self).deliver }
  mount_uploader :avatar, AvatarUploader

  private

  def mailchimp_sync
    begin
      Gibbon::API.lists.subscribe({
        :id => ENV['MAILCHIMP_LIST_ID'], 
        :email => {:email => self.email}, 
        :merge_vars => {FNAME: self.name}, 
        :double_optin => false
      })
      Gibbon::API.lists.static_segment_members_add({
        seg_id: ENV['MAILCHIMP_SEG_ID'],
        id: ENV['MAILCHIMP_LIST_ID'],
        batch: [{ email: self.email }]
      })
    rescue Exception => e
      logger.info e.message
    end
  end
end
