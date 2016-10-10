require 'spec_helper'

describe Api::V7::CoursesController, type: :controller do

  before(:each) do
    @source_path = "#{@test_tmp_dir}/fake_source"
    @repo_path = @test_tmp_dir + '/fake_remote_repo'
    @source_url = "file://#{@source_path}"
    create_bare_repo(@repo_path)
    @user = FactoryGirl.create(:user)
    @teacher = FactoryGirl.create(:user)
    @admin = FactoryGirl.create(:admin)
    @organization = FactoryGirl.create(:accepted_organization)
    Teachership.create(user: @teacher, organization: @organization)
  end

  describe 'GET index' do
    describe 'in JSON format' do
      def get_index_json(options = {})
        options = {
          format: 'json',
          api_version: ApiVersion::API_VERSION,
          organization_id: @organization.slug
        }.merge options
        @request.env['HTTP_AUTHORIZATION'] = 'Basic ' + Base64.encode64("#{@user.login}:#{@user.password}")
        get :index, options
        JSON.parse(response.body)
      end

      it 'renders all non-hidden courses in order by name' do
        FactoryGirl.create(:course, name: 'Course1', organization: @organization)
        FactoryGirl.create(:course, name: 'Course2', organization: @organization, hide_after: Time.now + 1.week)
        FactoryGirl.create(:course, name: 'Course3', organization: @organization)
        FactoryGirl.create(:course, name: 'ExpiredCourse', hide_after: Time.now - 1.week)
        FactoryGirl.create(:course, name: 'HiddenCourse', hidden: true)

        result = get_index_json

        expect(result['courses'].map { |c| c['name'] }).to eq(%w(Course1 Course2 Course3))
      end
    end

    describe 'GET show' do
      before :each do
        @course = FactoryGirl.create(:course)
      end

      describe 'in JSON format' do
        before :each do
          @course = FactoryGirl.create(:course, name: 'Course1')
          @course.exercises << FactoryGirl.create(:returnable_exercise, name: 'Exercise1', course: @course)
          @course.exercises << FactoryGirl.create(:returnable_exercise, name: 'Exercise2', course: @course)
          @course.exercises << FactoryGirl.create(:returnable_exercise, name: 'Exercise3', course: @course)
        end

        def get_show_json(options = {}, parse_json = true)
          options = {
            format: 'json',
            api_version: ApiVersion::API_VERSION,
            id: @course.id.to_s,
            organization_id: @organization.slug
          }.merge options
          @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user.login, @user.password)
          get :show, options
          if parse_json
            JSON.parse(response.body)
          else
            response.body
          end
        end

        it 'should render the exercises for each course' do
          result = get_show_json

          exs = result['course']['exercises']
          expect(exs[0]['name']).to eq('Exercise1')
          expect(exs[1]['name']).to eq('Exercise2')
          expect(exs[0]['zip_url']).to eq(exercise_url(@course.exercises[0].id, format: 'zip'))
          expect(exs[0]['return_url']).to eq(exercise_submissions_url(@course.exercises[0].id, format: 'json'))
        end

        it 'should include only visible exercises' do
          @course.exercises[0].hidden = true
          @course.exercises[0].save!
          @course.exercises[1].deadline_spec = [Date.yesterday.to_s].to_json
          @course.exercises[1].save!

          result = get_show_json

          names = result['course']['exercises'].map { |ex| ex['name'] }
          expect(names).not_to include('Exercise1')
          expect(names).to include('Exercise2')
          expect(names).to include('Exercise3')
        end

        it "should tell each the exercise's deadline" do
          @course.exercises[0].deadline_spec = [Time.zone.parse('2011-11-16 23:59:59+0200').to_s].to_json
          @course.exercises[0].save!

          result = get_show_json

          expect(result['course']['exercises'][0]['deadline']).to eq('2011-11-16T23:59:59.000+02:00')
        end

        it 'should tell for each exercise whether it has been attempted' do
          sub = FactoryGirl.create(:submission, course: @course, exercise: @course.exercises[0], user: @user)
          FactoryGirl.create(:test_case_run, submission: sub, successful: false)

          result = get_show_json

          exs = result['course']['exercises']
          expect(exs[0]['attempted']).to be_truthy
          expect(exs[1]['attempted']).to be_falsey
        end

        it 'should tell for each exercise whether it has been completed' do
          FactoryGirl.create(:submission, course: @course, exercise: @course.exercises[0], user: @user, all_tests_passed: true)

          result = get_show_json

          exs = result['course']['exercises']
          expect(exs[0]['completed']).to be_truthy
          expect(exs[1]['completed']).to be_falsey
        end

        describe 'and no user given' do
          it 'should respond with a 401' do
            controller.current_user = Guest.new
            get_show_json({ api_username: nil, api_password: nil }, false)
            expect(response.code.to_i).to eq(401)
          end
        end

        describe 'and the given user does not exist' do
          before :each do
            @user.destroy
          end

          it 'should respond with a 401' do
            get_show_json({}, false)
            expect(response.code.to_i).to eq(401)
          end
        end
      end
    end

  end
end
