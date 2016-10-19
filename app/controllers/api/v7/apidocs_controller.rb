class Api::V7::ApidocsController < ActionController::Base
  include Swagger::Blocks

  swagger_root do
    key :swagger, '2.0'
    info do
      key :version, '1.0.0'
      key :title, 'TMC API documentation'
      key :description, 'TMC API documentation'
      contact do
        key :name, 'TMC API Team'
        key :url, 'https://cs.helsinki.fi'
      end
      license do
        key :name, 'MIT'
      end
    end
    tag do
      key :name, 'api'
      key :description, 'API operations'
    end
    parameter :path_organization_id do
      key :name, :organization_id
      key :in, :path
      key :description, 'Organization\'s id'
      key :required, true
      key :type, :string
    end
    parameter :path_course_id do
      key :name, :course_id
      key :in, :path
      key :description, 'Course\'s id'
      key :required, true
      key :type, :integer
    end
    response :error do
      key :description, 'An error occurred'
      schema do
        key :title, :errors
        key :description, 'A list of error messages'
        key :type, :array
        items do
          key :type, :string
        end
      end
    end
    key :host, 'localhost:3000'
    key :consumes, ['application/json']
    key :produces, ['application/json']
  end

  # A list of all classes that have swagger_* declarations.
  SWAGGERED_CLASSES = [
    CoursesController,
    self,
  ].freeze

  def index
    render json: Swagger::Blocks.build_root_json(SWAGGERED_CLASSES)
  end
end
