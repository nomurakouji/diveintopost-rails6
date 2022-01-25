class AssignsController < ApplicationController
  before_action :authenticate_user!
  before_action :email_exist?, only: [:create]
  before_action :user_exist?, only: [:create]

  def create
    team = find_team(params[:team_id])
    user = email_reliable?(assign_params) ? User.find_or_create_by_email(assign_params) : nil
    if user
      team.invite_member(user)
      redirect_to team_url(team), notice: I18n.t('views.messages.assigned')
    else
      redirect_to team_url(team), notice: I18n.t('views.messages.failed_to_assign')
    end
  end

  def destroy
    # assign（例）
    # <Assign:0x00007fae403e5210
    # id: 19,user_id: 5,team_id: 4,
    assign = Assign.find(params[:id])
    # assign.user
    # <User id: 5, email: "cory@jerde-lehner.io",icon: nil, keep_team_id: nil>
    destroy_message = assign_destroy(assign, assign.user)
    redirect_to team_url(params[:team_id]), notice: destroy_message
  end

  private
  def assign_params
    params[:email]
  end

  def assign_destroy(assign, assigned_user)
    # assign.team.owner
    # <User id: 1, email: "elenor@schmitt-stokes.name",icon: nil, keep_team_id: 5>
    # assigned_user
    # <User id: 1, email: "elenor@schmitt-stokes.name", icon: nil, keep_team_id: 5>
    if assigned_user == assign.team.owner
      I18n.t('views.messages.cannot_delete_the_leader')
    # Assign (id: integer, user_id: integer, team_id: integer)
    # Assign.where(user_id: assigned_user.id)
    # <Assign:0x00007fe409d44b90,id: 5,user_id: 7,team_id: 2
    elsif Assign.where(user_id: assigned_user.id).count == 1
      I18n.t('views.messages.cannot_delete_only_a_member')
    # current_userの情報
    # <User id: 9, email: "christoper_flatley@jast-tillman.com", icon: nil, keep_team_id: 1>
    elsif ( current_user.id != assign.team.owner.id ) && ( current_user.id != assigned_user.id )
      I18n.t('views.messages.cannot_delete_leader_or_yourself')
    elsif assign.destroy
      set_next_team(assign, assigned_user)
      I18n.t('views.messages.delete_member')
    else
      I18n.t('views.messages.cannot_delete_member_4_some_reason')
    end
  end

  def email_exist?
    team = find_team(params[:team_id])
    if team.members.exists?(email: params[:email])
      redirect_to team_url(team), notice: I18n.t('views.messages.email_already_exists')
    end
  end

  def email_reliable?(address)
    address.match(/\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i)
  end

  def user_exist?
    team = find_team(params[:team_id])
    unless User.exists?(email: params[:email])
      redirect_to team_url(team), notice: I18n.t('views.messages.does_not_exist_email')
    end
  end

  # assigned_user
  # <User id: 8, email: "solomon.wilkinson@gleichner-torp.io",icon: nil, keep_team_id: nil>
  def set_next_team(assign, assigned_user)
    # Assign.find_by(user_id: assigned_user.id).team
    # <Team:0x00007fae3e74fe98
    # id: 2,(チームの)name: "Zaam-Dox",owner_id: 2,icon: nil>

    # Assign.find_by(user_id: assigned_user.id)
    # #<Assign:0x00007fae3e35cf98
    # id: 6,user_id: 8,team_id: 2,
    # find_by→ 条件に一致するものを引っ張る → user_id: assigned_user.idのとき。
    another_team = Assign.find_by(user_id: assigned_user.id).team
    # assigned_user.keep_team_id = nil
    # assign.team_id = 5
    change_keep_team(assigned_user, another_team) if assigned_user.keep_team_id == assign.team_id
    # def change_keep_team(user, current_team)
    # assigned_user.keep_team_id に assign.team_id を代入
  end

  def find_team(*)
    Team.friendly.find(params[:team_id])
  end
end
