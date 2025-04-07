;; peer-to-peer-trading.clar
;; Facilitates direct energy exchange between producers and consumers

(define-data-var next-offer-id uint u0)
(define-data-var next-trade-id uint u0)

;; Energy offer structure
(define-map energy-offers
  uint
  {
    seller: principal,
    producer-id: uint,
    energy-amount: uint,
    price-per-unit: uint,
    expiration: uint,
    active: bool
  }
)

;; Energy trades structure
(define-map energy-trades
  uint
  {
    offer-id: uint,
    buyer: principal,
    seller: principal,
    energy-amount: uint,
    total-price: uint,
    timestamp: uint,
    completed: bool
  }
)

;; Create a new energy offer
(define-public (create-offer
    (producer-id uint)
    (energy-amount uint)
    (price-per-unit uint)
    (expiration uint))
  (let
    (
      (offer-id (var-get next-offer-id))
      (caller tx-sender)
    )
    ;; Increment the offer ID counter
    (var-set next-offer-id (+ offer-id u1))

    ;; Store the offer details
    (map-set energy-offers offer-id {
      seller: caller,
      producer-id: producer-id,
      energy-amount: energy-amount,
      price-per-unit: price-per-unit,
      expiration: expiration,
      active: true
    })

    ;; Return the new offer ID
    (ok offer-id)
  )
)

;; Cancel an energy offer
(define-public (cancel-offer (offer-id uint))
  (let
    (
      (offer (unwrap! (map-get? energy-offers offer-id) (err u1)))
    )
    ;; Check if the caller is the seller
    (asserts! (is-eq tx-sender (get seller offer)) (err u2))
    ;; Check if the offer is still active
    (asserts! (get active offer) (err u3))

    ;; Deactivate the offer
    (map-set energy-offers offer-id {
      seller: (get seller offer),
      producer-id: (get producer-id offer),
      energy-amount: (get energy-amount offer),
      price-per-unit: (get price-per-unit offer),
      expiration: (get expiration offer),
      active: false
    })

    (ok true)
  )
)

;; Accept an energy offer and create a trade
(define-public (accept-offer (offer-id uint) (energy-amount uint))
  (let
    (
      (offer (unwrap! (map-get? energy-offers offer-id) (err u1)))
      (trade-id (var-get next-trade-id))
      (caller tx-sender)
      (block-time block-height)
    )
    ;; Check if the offer is active
    (asserts! (get active offer) (err u2))
    ;; Check if the offer hasn't expired
    (asserts! (< block-time (get expiration offer)) (err u3))
    ;; Check if the requested amount is available
    (asserts! (<= energy-amount (get energy-amount offer)) (err u4))
    ;; Check that buyer is not the seller
    (asserts! (not (is-eq caller (get seller offer))) (err u5))

    ;; Calculate the total price
    (let
      (
        (total-price (* energy-amount (get price-per-unit offer)))
        (remaining-energy (- (get energy-amount offer) energy-amount))
      )

      ;; Increment the trade ID counter
      (var-set next-trade-id (+ trade-id u1))

      ;; Create the trade
      (map-set energy-trades trade-id {
        offer-id: offer-id,
        buyer: caller,
        seller: (get seller offer),
        energy-amount: energy-amount,
        total-price: total-price,
        timestamp: block-time,
        completed: false
      })

      ;; Update the offer with remaining energy
      (map-set energy-offers offer-id {
        seller: (get seller offer),
        producer-id: (get producer-id offer),
        energy-amount: remaining-energy,
        price-per-unit: (get price-per-unit offer),
        expiration: (get expiration offer),
        active: (> remaining-energy u0)
      })

      ;; In a real implementation, handle the token transfer here

      ;; Return the trade ID
      (ok trade-id)
    )
  )
)

;; Complete a trade (could be triggered by an oracle confirming energy delivery)
(define-public (complete-trade (trade-id uint))
  (let
    (
      (trade (unwrap! (map-get? energy-trades trade-id) (err u1)))
    )
    ;; In a real implementation, add authorization checks here

    ;; Mark the trade as completed
    (map-set energy-trades trade-id {
      offer-id: (get offer-id trade),
      buyer: (get buyer trade),
      seller: (get seller trade),
      energy-amount: (get energy-amount trade),
      total-price: (get total-price trade),
      timestamp: (get timestamp trade),
      completed: true
    })

    (ok true)
  )
)

;; Get offer details
(define-read-only (get-offer (offer-id uint))
  (map-get? energy-offers offer-id)
)

;; Get trade details
(define-read-only (get-trade (trade-id uint))
  (map-get? energy-trades trade-id)
)
