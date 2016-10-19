require 'spec_helper'
require 'fileutils'

describe Api::V7::ExercisesController, type: :controller do
  describe 'GET show' do
    before :each do
      repo_path = Dir.pwd + '/remote_repo'
      create_bare_repo(repo_path)
      @organization = FactoryGirl.create(:accepted_organization, slug: 'slug')
      @course = Course.create!(name: 'mycourse', title: 'mycourse', source_backend: 'git', source_url: repo_path, organization: @organization)
      @repo = clone_course_repo(@course)
      @repo.copy_simple_exercise('MyExercise')
      @repo.add_commit_push

      @course.refresh
    end

    describe 'with .zip format' do
      it 'should offer the exercise as a downloadable zip', driver: :rack_test do
        visit "/api/v7/exercises/#{@course.exercises.find_by(name: "MyExercise").id}.zip"

        File.open('MyExercise.zip', 'wb') { |f| f.write(page.source) }
        system!('unzip -qq MyExercise.zip')

        expect(File).to be_a_directory('MyExercise')
        expect(File).to exist('MyExercise/src/SimpleStuff.java')
        expect(File).to exist('MyExercise/test/SimpleTest.java')
        expect(File).not_to exist('MyExercise/test/SimpleHiddenTest.java')
      end
    end

    after :all do
      FileUtils.rm_rf('test_tmp_dir')
    end
  end
end
