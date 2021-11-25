; Configure procedural/action code
(procedureConfig
  (desmosEntryPoint main)
  (pointerStack ps)
  (programCounter pc)
)

(= a 0)

(procedure main
  (while (< a 10)
    (if (> a 5)
      (-> a (+ a 1))
    )
  )
)