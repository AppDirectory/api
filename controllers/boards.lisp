(in-package :turtl)

(defroute (:post "/api/boards/users/([0-9a-f-]+)") (req res args)
  (catch-errors (res)
    (alet* ((user-id (car args))
            (board-data (post-var req "data")))
      (unless (string= (user-id req) user-id)
        (error 'insufficient-privileges :msg "You are trying to access another user's boards. For shame."))
      (alet ((board (add-board user-id board-data)))
        (track "board-add")
        (send-json res board)))))

(defroute (:put "/api/boards/([0-9a-f-]+)") (req res args)
  (catch-errors (res)
    (alet* ((user-id (user-id req))
            (board-id (car args))
            (board-data (post-var req "data")))
      (alet ((board (edit-board user-id board-id board-data)))
        (track "board-edit")
        (send-json res board)))))

(defroute (:delete "/api/boards/([0-9a-f-]+)") (req res args)
  (catch-errors (res)
    (alet* ((board-id (car args))
            (user-id (user-id req))
            (sync-ids (delete-board user-id board-id)))
      (track "board-delete")
      (let ((hash (make-hash-table :test #'equal)))
        (setf (gethash "sync_ids" hash) sync-ids)
        (send-json res hash)))))

(defroute (:put "/api/boards/([0-9a-f-]+)/invites/persona/([0-9a-f-]+)") (req res args)
  "Invite a persona to a board."
  (catch-errors (res)
    (alet* ((user-id (user-id req))
            (board-id (car args))
            (to-persona-id (cadr args))
            (from-persona-id (post-var req "from_persona"))
            (permissions (varint (post-var req "permissions") nil)))
      (multiple-future-bind (priv-entry sync-ids)
          (invite-persona-to-board user-id board-id from-persona-id to-persona-id permissions)
        (track "invite" `(:persona t))
        (let ((hash (convert-alist-hash priv-entry)))
          (setf (gethash "sync_ids" hash) sync-ids)
          (send-json res hash))))))

(defroute (:put "/api/boards/([0-9a-f-]+)/persona/([0-9a-f-]+)") (req res args)
  "Accept a board invite (persona-intiated)."
  (catch-errors (res)
    (alet* ((user-id (user-id req))
            (board-id (car args))
            (persona-id (cadr args))
            (sync-ids (accept-board-invite user-id board-id persona-id))
            (board (get-board-by-id board-id :get-notes t)))
      (track "invite-accept" `(:persona t))
      (setf (gethash "sync_ids" board) sync-ids)
      (send-json res board))))

(defroute (:delete "/api/boards/([0-9a-f-]+)/persona/([0-9a-f-]+)") (req res args)
  "Leave board share (persona-initiated)."
  (catch-errors (res)
    (alet* ((user-id (user-id req))
            (board-id (car args))
            (persona-id (cadr args))
            (sync-ids (leave-board-share user-id board-id persona-id)))
      (track "board-leave")
      (let ((hash (make-hash-table :test #'equal)))
        (setf (gethash "sync_ids" hash) sync-ids)
        (send-json res hash)))))

