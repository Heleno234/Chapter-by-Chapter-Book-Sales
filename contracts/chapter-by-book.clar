;; title: chapter-by-book
;; version: 1.0.0
;; summary: Chapter-by-chapter book sales with anti-plagiarism protection
;; description: Smart contract for selling books chapter by chapter with content verification

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-BOOK-NOT-FOUND (err u101))
(define-constant ERR-CHAPTER-NOT-FOUND (err u102))
(define-constant ERR-ALREADY-PURCHASED (err u103))
(define-constant ERR-INSUFFICIENT-FUNDS (err u104))
(define-constant ERR-BOOK-ALREADY-EXISTS (err u105))
(define-constant ERR-INVALID-PRICE (err u106))
(define-constant ERR-PLAGIARISM-DETECTED (err u107))
(define-constant ERR-CHAPTER-ALREADY-EXISTS (err u108))
(define-constant ERR-NOT-BOOK-OWNER (err u109))
(define-constant ERR-INVALID-CHAPTER (err u110))
(define-constant ERR-DISCOUNT-NOT-FOUND (err u111))
(define-constant ERR-INVALID-DISCOUNT (err u112))
(define-constant ERR-INSUFFICIENT-CHAPTERS (err u113))
(define-constant ERR-REVIEW-NOT-FOUND (err u114))
(define-constant ERR-ALREADY-REVIEWED (err u115))
(define-constant ERR-INSUFFICIENT-PURCHASE-HISTORY (err u116))
(define-constant ERR-INVALID-RATING (err u117))

(define-data-var contract-owner principal tx-sender)
(define-data-var total-books uint u0)
(define-data-var platform-fee-rate uint u250)

(define-map books
  { book-id: uint }
  {
    title: (string-ascii 100),
    author: principal,
    description: (string-ascii 500),
    cover-image: (string-ascii 200),
    total-chapters: uint,
    price-per-chapter: uint,
    created-at: uint,
    active: bool
  }
)

(define-map chapters
  { book-id: uint, chapter-number: uint }
  {
    title: (string-ascii 100),
    content-hash: (buff 32),
    content-preview: (string-ascii 200),
    published-at: uint,
    word-count: uint
  }
)

(define-map chapter-purchases
  { buyer: principal, book-id: uint, chapter-number: uint }
  {
    purchased-at: uint,
    price-paid: uint
  }
)

(define-map book-earnings
  { book-id: uint }
  {
    total-earned: uint,
    chapters-sold: uint
  }
)

(define-map author-stats
  { author: principal }
  {
    books-published: uint,
    total-earnings: uint,
    total-sales: uint
  }
)

(define-map content-hashes
  { content-hash: (buff 32) }
  {
    book-id: uint,
    chapter-number: uint,
    author: principal,
    published-at: uint
  }
)

(define-map user-libraries
  { user: principal, book-id: uint }
  {
    chapters-owned: (list 50 uint),
    total-spent: uint,
    first-purchase: uint
  }
)

(define-map bulk-discounts
  { book-id: uint, min-chapters: uint }
  {
    discount-rate: uint,
    created-at: uint,
    active: bool
  }
)

(define-map book-reviews
  { reviewer: principal, book-id: uint }
  {
    rating: uint,
    review-text: (string-ascii 500),
    chapters-read: uint,
    submitted-at: uint
  }
)

(define-map book-ratings
  { book-id: uint }
  {
    total-reviews: uint,
    total-rating-points: uint,
    average-rating: uint
  }
)

(define-map reviewer-stats
  { reviewer: principal }
  {
    total-reviews: uint,
    books-reviewed: uint
  }
)

(define-read-only (get-book (book-id uint))
  (map-get? books { book-id: book-id })
)

(define-read-only (get-chapter (book-id uint) (chapter-number uint))
  (map-get? chapters { book-id: book-id, chapter-number: chapter-number })
)

(define-read-only (has-purchased-chapter (buyer principal) (book-id uint) (chapter-number uint))
  (is-some (map-get? chapter-purchases { buyer: buyer, book-id: book-id, chapter-number: chapter-number }))
)

(define-read-only (get-book-earnings (book-id uint))
  (default-to { total-earned: u0, chapters-sold: u0 }
    (map-get? book-earnings { book-id: book-id }))
)

(define-read-only (get-author-stats (author principal))
  (default-to { books-published: u0, total-earnings: u0, total-sales: u0 }
    (map-get? author-stats { author: author }))
)

(define-read-only (check-plagiarism (content-hash (buff 32)))
  (map-get? content-hashes { content-hash: content-hash })
)

(define-read-only (get-user-library (user principal) (book-id uint))
  (map-get? user-libraries { user: user, book-id: book-id })
)

(define-read-only (get-total-books)
  (var-get total-books)
)

(define-read-only (get-platform-fee-rate)
  (var-get platform-fee-rate)
)

(define-read-only (get-bulk-discount (book-id uint) (min-chapters uint))
  (map-get? bulk-discounts { book-id: book-id, min-chapters: min-chapters })
)

(define-read-only (get-book-review (reviewer principal) (book-id uint))
  (map-get? book-reviews { reviewer: reviewer, book-id: book-id })
)

(define-read-only (get-book-rating (book-id uint))
  (default-to { total-reviews: u0, total-rating-points: u0, average-rating: u0 }
    (map-get? book-ratings { book-id: book-id }))
)

(define-read-only (get-reviewer-stats (reviewer principal))
  (default-to { total-reviews: u0, books-reviewed: u0 }
    (map-get? reviewer-stats { reviewer: reviewer }))
)

(define-read-only (has-reviewed-book (reviewer principal) (book-id uint))
  (is-some (map-get? book-reviews { reviewer: reviewer, book-id: book-id }))
)

(define-read-only (calculate-bulk-price (book-id uint) (chapter-count uint))
  (let (
    (book-data (unwrap! (get-book book-id) ERR-BOOK-NOT-FOUND))
    (base-price (* (get price-per-chapter book-data) chapter-count))
    (best-discount (fold find-best-discount (list u3 u5 u10 u20) { book-id: book-id, chapter-count: chapter-count, best-rate: u0 }))
  )
    (if (> (get best-rate best-discount) u0)
      (ok (- base-price (/ (* base-price (get best-rate best-discount)) u10000)))
      (ok base-price)
    )
  )
)

(define-private (find-best-discount (min-chapters uint) (state { book-id: uint, chapter-count: uint, best-rate: uint }))
  (let ((discount-data (get-bulk-discount (get book-id state) min-chapters)))
    (if (and 
          (is-some discount-data)
          (get active (unwrap-panic discount-data))
          (>= (get chapter-count state) min-chapters)
          (> (get discount-rate (unwrap-panic discount-data)) (get best-rate state))
        )
      (merge state { best-rate: (get discount-rate (unwrap-panic discount-data)) })
      state
    )
  )
)

(define-public (create-book (title (string-ascii 100)) (description (string-ascii 500)) (cover-image (string-ascii 200)) (price-per-chapter uint))
  (let ((new-book-id (+ (var-get total-books) u1)))
    (asserts! (> price-per-chapter u0) ERR-INVALID-PRICE)
    (asserts! (is-none (map-get? books { book-id: new-book-id })) ERR-BOOK-ALREADY-EXISTS)
    
    (map-set books
      { book-id: new-book-id }
      {
        title: title,
        author: tx-sender,
        description: description,
        cover-image: cover-image,
        total-chapters: u0,
        price-per-chapter: price-per-chapter,
        created-at: stacks-block-height,
        active: true
      }
    )
    
    (map-set book-earnings
      { book-id: new-book-id }
      { total-earned: u0, chapters-sold: u0 }
    )
    
    (let ((current-stats (get-author-stats tx-sender)))
      (map-set author-stats
        { author: tx-sender }
        {
          books-published: (+ (get books-published current-stats) u1),
          total-earnings: (get total-earnings current-stats),
          total-sales: (get total-sales current-stats)
        }
      )
    )
    
    (var-set total-books new-book-id)
    (ok new-book-id)
  )
)

(define-public (publish-chapter (book-id uint) (chapter-number uint) (title (string-ascii 100)) (content-hash (buff 32)) (content-preview (string-ascii 200)) (word-count uint))
  (let ((book-data (unwrap! (get-book book-id) ERR-BOOK-NOT-FOUND)))
    (asserts! (is-eq (get author book-data) tx-sender) ERR-NOT-BOOK-OWNER)
    (asserts! (get active book-data) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (get-chapter book-id chapter-number)) ERR-CHAPTER-ALREADY-EXISTS)
    (asserts! (is-none (check-plagiarism content-hash)) ERR-PLAGIARISM-DETECTED)
    (asserts! (> chapter-number u0) ERR-INVALID-CHAPTER)
    
    (map-set chapters
      { book-id: book-id, chapter-number: chapter-number }
      {
        title: title,
        content-hash: content-hash,
        content-preview: content-preview,
        published-at: stacks-block-height,
        word-count: word-count
      }
    )
    
    (map-set content-hashes
      { content-hash: content-hash }
      {
        book-id: book-id,
        chapter-number: chapter-number,
        author: tx-sender,
        published-at: stacks-block-height
      }
    )
    
    (if (>= chapter-number (get total-chapters book-data))
      (map-set books
        { book-id: book-id }
        (merge book-data { total-chapters: chapter-number })
      )
      true
    )
    
    (ok true)
  )
)

(define-public (purchase-chapter (book-id uint) (chapter-number uint))
  (let (
    (book-data (unwrap! (get-book book-id) ERR-BOOK-NOT-FOUND))
    (chapter-data (unwrap! (get-chapter book-id chapter-number) ERR-CHAPTER-NOT-FOUND))
    (price (get price-per-chapter book-data))
    (platform-fee (/ (* price (var-get platform-fee-rate)) u10000))
    (author-earnings (- price platform-fee))
  )
    (asserts! (get active book-data) ERR-NOT-AUTHORIZED)
    (asserts! (not (has-purchased-chapter tx-sender book-id chapter-number)) ERR-ALREADY-PURCHASED)
    
    (try! (stx-transfer? price tx-sender (as-contract tx-sender)))
    (try! (as-contract (stx-transfer? author-earnings tx-sender (get author book-data))))
    (try! (as-contract (stx-transfer? platform-fee tx-sender (var-get contract-owner))))
    
    (map-set chapter-purchases
      { buyer: tx-sender, book-id: book-id, chapter-number: chapter-number }
      {
        purchased-at: stacks-block-height,
        price-paid: price
      }
    )
    
    (let ((current-earnings (get-book-earnings book-id)))
      (map-set book-earnings
        { book-id: book-id }
        {
          total-earned: (+ (get total-earned current-earnings) author-earnings),
          chapters-sold: (+ (get chapters-sold current-earnings) u1)
        }
      )
    )
    
    (let ((current-stats (get-author-stats (get author book-data))))
      (map-set author-stats
        { author: (get author book-data) }
        {
          books-published: (get books-published current-stats),
          total-earnings: (+ (get total-earnings current-stats) author-earnings),
          total-sales: (+ (get total-sales current-stats) u1)
        }
      )
    )
    
    (let ((user-lib (default-to 
          { chapters-owned: (list), total-spent: u0, first-purchase: stacks-block-height }
          (get-user-library tx-sender book-id))))
      (map-set user-libraries
        { user: tx-sender, book-id: book-id }
        {
          chapters-owned: (unwrap! (as-max-len? (append (get chapters-owned user-lib) chapter-number) u50) ERR-NOT-AUTHORIZED),
          total-spent: (+ (get total-spent user-lib) price),
          first-purchase: (get first-purchase user-lib)
        }
      )
    )
    
    (ok true)
  )
)

(define-public (deactivate-book (book-id uint))
  (let ((book-data (unwrap! (get-book book-id) ERR-BOOK-NOT-FOUND)))
    (asserts! (is-eq (get author book-data) tx-sender) ERR-NOT-BOOK-OWNER)
    
    (map-set books
      { book-id: book-id }
      (merge book-data { active: false })
    )
    
    (ok true)
  )
)

(define-public (reactivate-book (book-id uint))
  (let ((book-data (unwrap! (get-book book-id) ERR-BOOK-NOT-FOUND)))
    (asserts! (is-eq (get author book-data) tx-sender) ERR-NOT-BOOK-OWNER)
    
    (map-set books
      { book-id: book-id }
      (merge book-data { active: true })
    )
    
    (ok true)
  )
)

(define-public (update-platform-fee (new-fee-rate uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-fee-rate u1000) ERR-INVALID-PRICE)
    (var-set platform-fee-rate new-fee-rate)
    (ok true)
  )
)

(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (var-set contract-owner new-owner)
    (ok true)
  )
)

(define-public (create-bulk-discount (book-id uint) (min-chapters uint) (discount-rate uint))
  (let ((book-data (unwrap! (get-book book-id) ERR-BOOK-NOT-FOUND)))
    (asserts! (is-eq (get author book-data) tx-sender) ERR-NOT-BOOK-OWNER)
    (asserts! (>= min-chapters u3) ERR-INSUFFICIENT-CHAPTERS)
    (asserts! (and (> discount-rate u0) (<= discount-rate u5000)) ERR-INVALID-DISCOUNT)
    (asserts! (is-none (get-bulk-discount book-id min-chapters)) ERR-BOOK-ALREADY-EXISTS)
    
    (map-set bulk-discounts
      { book-id: book-id, min-chapters: min-chapters }
      {
        discount-rate: discount-rate,
        created-at: stacks-block-height,
        active: true
      }
    )
    
    (ok true)
  )
)

(define-public (update-bulk-discount (book-id uint) (min-chapters uint) (new-discount-rate uint))
  (let ((book-data (unwrap! (get-book book-id) ERR-BOOK-NOT-FOUND)))
    (asserts! (is-eq (get author book-data) tx-sender) ERR-NOT-BOOK-OWNER)
    (asserts! (and (> new-discount-rate u0) (<= new-discount-rate u5000)) ERR-INVALID-DISCOUNT)
    (asserts! (is-some (get-bulk-discount book-id min-chapters)) ERR-DISCOUNT-NOT-FOUND)
    
    (let ((current-discount (unwrap! (get-bulk-discount book-id min-chapters) ERR-DISCOUNT-NOT-FOUND)))
      (map-set bulk-discounts
        { book-id: book-id, min-chapters: min-chapters }
        (merge current-discount { discount-rate: new-discount-rate })
      )
    )
    
    (ok true)
  )
)

(define-public (toggle-bulk-discount (book-id uint) (min-chapters uint))
  (let ((book-data (unwrap! (get-book book-id) ERR-BOOK-NOT-FOUND)))
    (asserts! (is-eq (get author book-data) tx-sender) ERR-NOT-BOOK-OWNER)
    (asserts! (is-some (get-bulk-discount book-id min-chapters)) ERR-DISCOUNT-NOT-FOUND)
    
    (let ((current-discount (unwrap! (get-bulk-discount book-id min-chapters) ERR-DISCOUNT-NOT-FOUND)))
      (map-set bulk-discounts
        { book-id: book-id, min-chapters: min-chapters }
        (merge current-discount { active: (not (get active current-discount)) })
      )
    )
    
    (ok true)
  )
)

(define-public (purchase-chapters-bulk (book-id uint) (chapter-numbers (list 20 uint)))
  (let (
    (book-data (unwrap! (get-book book-id) ERR-BOOK-NOT-FOUND))
    (chapter-count (len chapter-numbers))
    (discounted-price (unwrap! (calculate-bulk-price book-id chapter-count) ERR-BOOK-NOT-FOUND))
    (platform-fee (/ (* discounted-price (var-get platform-fee-rate)) u10000))
    (author-earnings (- discounted-price platform-fee))
  )
    (asserts! (get active book-data) ERR-NOT-AUTHORIZED)
    (asserts! (>= chapter-count u3) ERR-INSUFFICIENT-CHAPTERS)
    (asserts! (get valid (fold check-chapter-availability chapter-numbers { book-id: book-id, valid: true })) ERR-CHAPTER-NOT-FOUND)
    
    (try! (stx-transfer? discounted-price tx-sender (as-contract tx-sender)))
    (try! (as-contract (stx-transfer? author-earnings tx-sender (get author book-data))))
    (try! (as-contract (stx-transfer? platform-fee tx-sender (var-get contract-owner))))
    
    (fold process-bulk-purchase chapter-numbers book-id)
    
    (let ((current-earnings (get-book-earnings book-id)))
      (map-set book-earnings
        { book-id: book-id }
        {
          total-earned: (+ (get total-earned current-earnings) author-earnings),
          chapters-sold: (+ (get chapters-sold current-earnings) chapter-count)
        }
      )
    )
    
    (let ((current-stats (get-author-stats (get author book-data))))
      (map-set author-stats
        { author: (get author book-data) }
        {
          books-published: (get books-published current-stats),
          total-earnings: (+ (get total-earnings current-stats) author-earnings),
          total-sales: (+ (get total-sales current-stats) chapter-count)
        }
      )
    )
    
    (let ((user-lib (default-to 
          { chapters-owned: (list), total-spent: u0, first-purchase: stacks-block-height }
          (get-user-library tx-sender book-id))))
      (map-set user-libraries
        { user: tx-sender, book-id: book-id }
        {
          chapters-owned: (unwrap! (as-max-len? (concat (get chapters-owned user-lib) chapter-numbers) u50) ERR-NOT-AUTHORIZED),
          total-spent: (+ (get total-spent user-lib) discounted-price),
          first-purchase: (get first-purchase user-lib)
        }
      )
    )
    
    (ok discounted-price)
  )
)

(define-private (check-chapter-availability (chapter-number uint) (state { book-id: uint, valid: bool }))
  (let ((chapter-exists (is-some (get-chapter (get book-id state) chapter-number)))
        (not-purchased (not (has-purchased-chapter tx-sender (get book-id state) chapter-number))))
    (merge state { valid: (and (get valid state) chapter-exists not-purchased) })
  )
)

(define-private (process-bulk-purchase (chapter-number uint) (book-id uint))
  (begin
    (map-set chapter-purchases
      { buyer: tx-sender, book-id: book-id, chapter-number: chapter-number }
      {
        purchased-at: stacks-block-height,
        price-paid: u0
      }
    )
    book-id
  )
)

(define-public (submit-review (book-id uint) (rating uint) (review-text (string-ascii 500)))
  (let (
    (book-data (unwrap! (get-book book-id) ERR-BOOK-NOT-FOUND))
    (user-library (unwrap! (get-user-library tx-sender book-id) ERR-INSUFFICIENT-PURCHASE-HISTORY))
    (chapters-owned-count (len (get chapters-owned user-library)))
  )
    (asserts! (>= rating u1) ERR-INVALID-RATING)
    (asserts! (<= rating u5) ERR-INVALID-RATING)
    (asserts! (>= chapters-owned-count u1) ERR-INSUFFICIENT-PURCHASE-HISTORY)
    (asserts! (is-none (map-get? book-reviews { reviewer: tx-sender, book-id: book-id })) ERR-ALREADY-REVIEWED)
    
    (map-set book-reviews
      { reviewer: tx-sender, book-id: book-id }
      {
        rating: rating,
        review-text: review-text,
        chapters-read: chapters-owned-count,
        submitted-at: stacks-block-height
      }
    )
    
    (let ((current-ratings (default-to { total-reviews: u0, total-rating-points: u0, average-rating: u0 } (map-get? book-ratings { book-id: book-id }))))
      (let (
        (new-total-reviews (+ (get total-reviews current-ratings) u1))
        (new-total-points (+ (get total-rating-points current-ratings) rating))
        (new-average (/ (* new-total-points u100) new-total-reviews))
      )
        (map-set book-ratings
          { book-id: book-id }
          {
            total-reviews: new-total-reviews,
            total-rating-points: new-total-points,
            average-rating: new-average
          }
        )
      )
    )
    
    (let ((current-reviewer-stats (default-to { total-reviews: u0, books-reviewed: u0 } (map-get? reviewer-stats { reviewer: tx-sender }))))
      (map-set reviewer-stats
        { reviewer: tx-sender }
        {
          total-reviews: (+ (get total-reviews current-reviewer-stats) u1),
          books-reviewed: (+ (get books-reviewed current-reviewer-stats) u1)
        }
      )
    )
    
    (ok true)
  )
)

(define-public (update-review (book-id uint) (new-rating uint) (new-review-text (string-ascii 500)))
  (let (
    (book-data (unwrap! (get-book book-id) ERR-BOOK-NOT-FOUND))
    (existing-review (unwrap! (map-get? book-reviews { reviewer: tx-sender, book-id: book-id }) ERR-REVIEW-NOT-FOUND))
    (user-library (unwrap! (get-user-library tx-sender book-id) ERR-INSUFFICIENT-PURCHASE-HISTORY))
    (chapters-owned-count (len (get chapters-owned user-library)))
    (old-rating (get rating existing-review))
  )
    (asserts! (>= new-rating u1) ERR-INVALID-RATING)
    (asserts! (<= new-rating u5) ERR-INVALID-RATING)
    
    (map-set book-reviews
      { reviewer: tx-sender, book-id: book-id }
      {
        rating: new-rating,
        review-text: new-review-text,
        chapters-read: chapters-owned-count,
        submitted-at: stacks-block-height
      }
    )
    
    (let ((current-ratings (unwrap! (map-get? book-ratings { book-id: book-id }) ERR-REVIEW-NOT-FOUND)))
      (let (
        (adjusted-total-points (+ (- (get total-rating-points current-ratings) old-rating) new-rating))
        (new-average (/ (* adjusted-total-points u100) (get total-reviews current-ratings)))
      )
        (map-set book-ratings
          { book-id: book-id }
          {
            total-reviews: (get total-reviews current-ratings),
            total-rating-points: adjusted-total-points,
            average-rating: new-average
          }
        )
      )
    )
    
    (ok true)
  )
)
