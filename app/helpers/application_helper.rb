module ApplicationHelper
  def mobile_user_agent?
    request.env["HTTP_USER_AGENT"] &&
        (request.env["HTTP_USER_AGENT"][/(iPhone|iPod|iPad).+AppleWebKit/] ||
            request.env["HTTP_USER_AGENT"][/Android/] ||
            request.env["HTTP_USER_AGENT"][/BlackBerry/] ||
            request.env["HTTP_USER_AGENT"][/Windows Phone/])
  end
end