class ContactMailer < ApplicationMailer
  def contact_mail(user_emails)
    #個別送付:@user = agenda.user
    @user = user_emails
    binding.irb
      mail to: @user, subject: "アジェンダと紐づく記事とコメント削除のメール"
    
  end
end
