module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    private

    def connect
      self.current_user = find_verified_user
    end

    def find_verified_user
      session = Session.find_by(id: cookies.signed[:session_id])
      if session
        session.user
      else
        reject_unauthorized_connection
      end
    end
  end
end
