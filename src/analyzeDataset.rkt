#lang s-exp rosette

; Get the dataset

(require (planet neil/csv:1:=7))
(require (planet williams/describe/describe))
(require rosette/lib/meta/meta)


(define datasetRaw (csv->list (open-input-file "sampleAirDataset3.csv")))

(define columnLabels (car datasetRaw))
(define columnTypes (cadr datasetRaw))
(define oldMins (caddr datasetRaw))
(define oldMaxes (cadddr datasetRaw))
(define remainder (cddddr datasetRaw))
(define newMins (car remainder))
(define newMaxes (cadr remainder))
(define datasetOnly (cddr remainder))

; Which columns will we turn into numeric columns?
(define dataset (map (lambda (row) (map (lambda (cell) (if (string->number cell) (string->number cell) cell)) row)) datasetOnly))

(current-bitwidth 6) ;TODO: set bitwdith according to user-given limit

; User configuration stuff

(define targetColumnName "ARR_DELAY")
(define smallRowSetShouldHaveHighValue? #t)

(define (index-of lst ele)
  (let loop ((lst lst)
             (idx 0))
    (cond ((empty? lst) #f)
          ((equal? (first lst) ele) idx)
          (else (loop (rest lst) (add1 idx))))))

(define targetColumnIndex (index-of columnLabels targetColumnName))

; Score calculations
; score is tuple of form: (predTrueSum, predFalseSum, predTrueCount, predFalseCount)

(define score (lambda (pred dataset colIndex)
  (foldl (lambda (row tuple)
           (begin
           (if (pred row)
               (begin `( ,(+ (list-ref tuple 0) (list-ref row colIndex)) ,(list-ref tuple 1) ,(+ (list-ref tuple 2) 1) ,(list-ref tuple 3)))
               (begin `( ,(list-ref tuple 0) ,(+ (list-ref tuple 1) (list-ref row colIndex)) ,(list-ref tuple 2) ,(+ (list-ref tuple 3) 1)))
               )))
         '(0 0 0 0) dataset)))


(define avgTrue (lambda (tuple)
  (/ (list-ref tuple 0) (list-ref tuple 2))))

(define numRowsTrue (lambda (tuple)
                      (list-ref tuple 2)))

; What's our value to start?

(define neutralPred (lambda (row) #t))

(define startScoreTuple (score neutralPred dataset targetColumnIndex))
(define startScore (avgTrue startScoreTuple))
(newline)

(define (scoreBeats targetScore pred ds colIndex)
                     (let ([scoreTuple (score pred ds colIndex)])
                       (begin 
                       (assert (>= (avgTrue scoreTuple) targetScore))
                       )))

(define (scoreBeatsSimple targetScore pred ds colIndex)
                     (begin (assert (> (avgTrue (score pred ds colIndex)) targetScore)) ))

; Actual synthesis

(define-synthax (simpleFilterGrammar datasetRow colIndexes ... )
  (let ([limit (??)] [colIndex [choose colIndexes ... ]]) (> (list-ref datasetRow colIndex) limit)))

(define testColumnName "DEP_TIME")
(define testColumnIndex (index-of columnLabels testColumnName))

; A sketch with a hole to be filled with an expr
(define (filterSynthesized row) (simpleFilterGrammar row testColumnIndex))
; todo: put the proper numbers in instead of testcolumnindex
(define synthesizedFilter
   (synthesize #:forall `()
    #:guarantee (scoreBeatsSimple startScore filterSynthesized dataset targetColumnIndex)))

(print-forms synthesizedFilter)
