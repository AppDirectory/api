(in-package :turtl)

(defroute (:post "/api/boards/users/([0-9a-f-]+)") (req res args)
  (catch-errors (res)
    (alet* ((user-id (car args))
            (board-data (post-var req "data")))
      (unless (string= (user-id req) user-id)
        (error 'insufficient-privileges :msg "You are trying to access another user's boards. For shame."))
      (alet ((board (add-board user-id board-data)))
        (send-json res board)))))

(defroute (:put "/api/boards/([0-9a-f-]+)") (req res args)
  (catch-errors (res)
    (alet* ((user-id (user-id req))
            (board-id (car args))
            (board-data (post-var req "data")))
      (alet ((board (edit-board user-id board-id board-data)))
        (send-json res board)))))

(defroute (:delete "/api/boards/([0-9a-f-]+)") (req res args)
  (catch-errors (res)
    (alet* ((board-id (car args))
            (user-id (user-id req))
            (nil (delete-board user-id board-id)))
      (send-json res t))))

(defroute (:put "/api/boards/([0-9a-f-]+)/invites/persona/([0-9a-f-]+)") (req res args)
  "Invite a persona to a board."
  (catch-errors (res)
    (alet* ((user-id (user-id req))
            (board-id (car args))
            (persona-id (cadr args))
            (permissions (varint (post-var req "permissions") nil)))
      (multiple-future-bind (nil priv-entry)
          (set-board-persona-permissions user-id board-id persona-id permissions :invite t)
        (send-json res (convert-alist-hash priv-entry))))))

(defroute (:put "/api/boards/([0-9a-f-]+)/persona/([0-9a-f-]+)") (req res args)
  "Accept a board invite (persona-intiated)."
  (catch-errors (res)
    (alet* ((user-id (user-id req))
            (board-id (car args))
            (persona-id (cadr args))
            (nil (accept-board-invite user-id board-id persona-id))
            (board (get-board-by-id board-id :get-notes t)))
      (send-json res board))))

(defroute (:delete "/api/boards/([0-9a-f-]+)/persona/([0-9a-f-]+)") (req res args)
  "Leave board share (persona-initiated)."
  (catch-errors (res)
    (alet* ((user-id (user-id req))
            (board-id (car args))
            (persona-id (cadr args))
            (nil (leave-board-share user-id board-id persona-id)))
      (send-json res t))))


