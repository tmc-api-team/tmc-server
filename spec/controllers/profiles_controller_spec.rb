require 'spec_helper'

describe ProfilesController do
  describe "GET show" do
    describe "when accessed as a guest" do
      before :each do
        controller.current_user.should be_guest
      end
      
      it "should redirect to the front page" do
        get :show
        response.status.should == 403
      end
    end
    
    describe "when accessed as a logged in user" do
      before :each do
        controller.current_user = Factory.create(:user)
      end
      
      it "should show the profile page" do
        get :show
        response.should be_success
      end
    end
  end
  
  describe "PUT update" do
    before :each do
      @user = Factory.create(:user, :email => 'oldemail')
      controller.current_user = @user
    end
    
    it "should save the email field" do
      put :update, :user => { :email => 'newemail' }
      response.should redirect_to(profile_path)
      @user.reload.email.should == 'newemail'
    end
    
    it "should not allow changing the login" do
      old_login = @user.login
      put :update, :user => { :email => 'newemail', :login => 'newlogin' }
      response.should redirect_to(profile_path)
      @user.reload.login.should == old_login
    end
    
    describe "changing the password" do
      let(:params) { { :email => 'newemail' } }
      
      before :each do
        @user.password = 'oldpassword'
        @user.save!
        @user.reload.should have_password('oldpassword')
      end
      
      it "should not try to change the password unless specified" do
        put :update, :user => params
        response.should redirect_to(profile_path)
        @user.reload.should have_password('oldpassword')
      end
      
      it "should change the password if the old password matched and both new password fields were the same" do
        put :update, :user => params.merge({
          :old_password => 'oldpassword',
          :password => 'newpassword',
          :password_repeat => 'newpassword'
        })
        response.should redirect_to(profile_path)
        @user.reload.should have_password('newpassword')
      end
      
      it "should not change the password if the old password was wrong" do
        put :update, :user => params.merge({
          :old_password => 'wrongpassword',
          :password => 'newpassword',
          :password_repeat => 'newpassword'
        })
        response.status.should == 403
        @user.reload.should have_password('oldpassword')
      end
      
      it "should not change the password if the new password fields were not the same" do
        put :update, :user => params.merge({
          :old_password => 'oldpassword',
          :password => 'newpassword',
          :password_repeat => 'foo'
        })
        response.status.should == 403
        @user.reload.should have_password('oldpassword')
      end
      
      it "should not allow changing to a blank password" do
        put :update, :user => params.merge({
          :old_password => 'oldpassword',
          :password => '',
          :password_repeat => ''
        })
        response.status.should == 403
        @user.reload.should have_password('oldpassword')
      end
    end
  end
end
