class Api::Beta::ApidocsController < ActionController::Base
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
    parameter :api_version do
      key :name, :api_version
      key :in, :query
      key :description, 'API version'
      key :required, true
      key :type, :integer
      key :default, 7
    end
    parameter :client_name do
      key :name, :client
      key :in, :query
      key :description, 'Client name'
      key :required, false
      key :type, :string
      key :default, ""
    end
    parameter :client_version do
      key :name, :client_version
      key :in, :query
      key :description, 'Client version'
      key :required, true
      key :type, :string
      key :default, "0.9.3"
    end
    parameter :organization_id do
      key :name, :organization_id
      key :in, :path
      key :description, 'ID of organization'
      key :required, true
      key :type, :string
    end
    tag do
      key :name, 'api'
      key :description, 'API operations'
    end
    key :host, 'localhost:3000'
    key :consumes, ['application/json']
    key :produces, ['application/json']
  end

  # A list of all classes that have swagger_* declarations.
  SWAGGERED_CLASSES = [
    CourseIdInformationController,
    CoursesController,
    self,
  ].freeze

  def index
    render json: Swagger::Blocks.build_root_json(SWAGGERED_CLASSES)
  end
end
