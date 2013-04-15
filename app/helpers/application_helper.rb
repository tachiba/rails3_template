module ApplicationHelper
  def tablet?
    return false unless request.env["HTTP_USER_AGENT"]
    user_agent = request.env["HTTP_USER_AGENT"]

    return true if user_agent[/iPad.+AppleWebKit/]

    if user_agent[/Android/]
      if user_agent[/Mobile/]
        return false
      else
        return true
      end
    end
  end
end