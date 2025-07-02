class Command::VisitUrl < Command
  store_accessor :data, :url

  def title
    "Visit #{url}"
  end

  def execute
    redirect_to real_url
  end

  private
    def real_url
      case url
      when String
        if url.start_with?(context.script_name)
          url
        else
          [ context&.script_name, url ].compact.join
        end
      else
        url
      end
    end
end
