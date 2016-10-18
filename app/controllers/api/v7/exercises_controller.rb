class Api::V7::ExercisesController < Api::V7::BaseController
  include Swagger::Blocks

  swagger_path '/exercises/{exercise.id}.zip' do
    operation :get do
      key :description, 'Starts to download the exercise in zip format'
      key :operationId, 'downloadExercise'
      key :tags, [
        'exercise'
      ]
      parameter '$ref': '#/parameters/path_exercise_id'
      response 401, '$ref': '#/responses/error'
      response 200 do
        key :description, 'download exercise as zip'
      end
    end
  end

  def show
    @exercise = Exercise.find(params[:id])
    @course = Course.lock('FOR SHARE').find(@exercise.course_id)
    @organization = @course.organization
    authorize! :read, @course
    authorize! :read, @exercise

    respond_to do |format|
      format.zip do
        authorize! :download, @exercise
        send_file @exercise.stub_zip_file_path
      end
      format.json do
      end
    end
  end
end
