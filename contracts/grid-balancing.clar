;; grid-balancing.clar
;; Manages overall stability of the energy network

(define-data-var grid-demand uint u0)
(define-data-var grid-supply uint u0)
(define-data-var grid-balance-threshold uint u100) ;; Threshold for imbalance (in percentage * 100)
(define-data-var grid-admin principal tx-sender)

(define-map grid-regions
  (string-utf8 50)
  {
    demand: uint,
    supply: uint,
    last-updated: uint
  }
)

;; Update the grid demand
(define-public (update-grid-demand (new-demand uint))
  (begin
    ;; In a real implementation, add authorization checks here
    (var-set grid-demand new-demand)
    (ok true)
  )
)

;; Update the grid supply
(define-public (update-grid-supply (new-supply uint))
  (begin
    ;; In a real implementation, add authorization checks here
    (var-set grid-supply new-supply)
    (ok true)
  )
)

;; Update a specific grid region
(define-public (update-grid-region
    (region-name (string-utf8 50))
    (demand uint)
    (supply uint))
  (begin
    ;; In a real implementation, add authorization checks here
    (map-set grid-regions region-name {
      demand: demand,
      supply: supply,
      last-updated: block-height
    })
    (ok true)
  )
)

;; Check if the grid is balanced
(define-read-only (is-grid-balanced)
  (let
    (
      (demand (var-get grid-demand))
      (supply (var-get grid-supply))
      (threshold (var-get grid-balance-threshold))
    )
    ;; If demand is 0, check if supply is also 0
    (if (is-eq demand u0)
      (is-eq supply u0)
      ;; Otherwise, calculate the percentage difference
      (let
        (
          (diff (if (> supply demand)
                  (- supply demand)
                  (- demand supply)))
          (percentage (* (/ (* diff u10000) demand) u100))
        )
        (<= percentage threshold)
      )
    )
  )
)

;; Get the current grid status
(define-read-only (get-grid-status)
  {
    demand: (var-get grid-demand),
    supply: (var-get grid-supply),
    balanced: (is-grid-balanced)
  }
)

;; Get a specific region's status
(define-read-only (get-region-status (region-name (string-utf8 50)))
  (map-get? grid-regions region-name)
)

;; Set the balance threshold
(define-public (set-balance-threshold (new-threshold uint))
  (begin
    ;; Only the admin can change the threshold
    (asserts! (is-eq tx-sender (var-get grid-admin)) (err u1))
    (var-set grid-balance-threshold new-threshold)
    (ok true)
  )
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    ;; Only the current admin can transfer admin rights
    (asserts! (is-eq tx-sender (var-get grid-admin)) (err u1))
    (var-set grid-admin new-admin)
    (ok true)
  )
)
