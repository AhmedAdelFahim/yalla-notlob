class FriendsController < ApplicationController

  before_action :auth

  def auth
    if ! current_user
      redirect_to new_user_session_path, notice: 'You are not logged in.'
    end
  end

  def index
    # if user_signed_in? 
    #   redirect_to new_user_registration_path, notice: "Please Login to view that page!"
    # end 
    @user=current_user

    # p @user.friends.length   ##rows in friends where current_user.id is friend_id
    # p @user.friends_data.length       ##rows in friends where current_user.id is user_id



    ##users that current user can add (all users except [current users,users that current_user adde ,and users who added current user])
    @users=User.all.where.not(id:current_user.id).where.not(id:@user.friends.pluck(:user_id)).where.not(id:@user.friends_data.pluck(:friend_id)) 
    
   
    # @friendsAll=User.all.where(id:@user.friends.pluck(:user_id)).where(id:@user.friends_data.pluck(:user_id))

    @friendsAll=User.all.where(id:[@user.added_friends.pluck(:user_id)]).or(User.all.where(id:[@user.friends.pluck(:friend_id)]))

    
   
  end

  def create
    @user=current_user
    friendFromUsersTable=User.all.where(email:params["email"]).first()
    @friendsAll=User.all.where(id:[@user.added_friends.pluck(:user_id)]).or(User.all.where(id:[@user.friends.pluck(:friend_id)]))

    if params["email"]==@user.email
      flash[:error] = "you can't add yourself to your friends."
      return redirect_to :action => 'index'
    elsif  !friendFromUsersTable
      flash[:error] = "No such user"
      return redirect_to :action => 'index'
    else
      for friend in @friendsAll do
        if friend.email==params["email"]
                flash[:error] = "your are already friends."
                return redirect_to :action => 'index'
        end
      end 
      @friend = Friend.new
      @friend.user_id =current_user.id
      @friend.friend_id = friendFromUsersTable.id
      @friend.save
      p @friend
      if @friend.save and 
        flash[:notice] = "Added friend."
        redirect_to :friends
      else
        flash[:notice] = "Unable to add friend."
        redirect_to :friends
      end  
    end  
  end

  def destroy
    Friend.where(friend_id:params["friend_id"]).where(user_id:current_user.id ).destroy_all
    Friend.where(friend_id:current_user.id).where(user_id:params["friend_id"] ).destroy_all

    redirect_to :friends
    # respond_to do |format|
    #   format.html { redirect_to friends, notice: 'unfriend was successfully done.' }
    #   format.json { head :no_content }
    # end
  end

  def new
  end

  def show
  end
end
