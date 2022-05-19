#lang racket

(require 
    "builtins.rkt"
    "expression-compiler.rkt"
    json
    racket/hash
)





(define (get-graph-display-properties . display-properties)
    (flatten (map (lambda (prop)
        (match (car prop)
            ('color-latex (list `colorLatex (compile-lispsmos-expression (cadr prop))))
            ('color (list 'color (symbol->string (cadr prop))))
            
            ('line-opacity (list 'lineOpacity (compile-lispsmos-expression (cadr prop))))
            ('line-width (list 'lineWidth (compile-lispsmos-expression (cadr prop))))
            ('line-style (list 'lineStyle (symbol->string (cadr prop))))

            ('point-opacity (list 'pointOpacity (compile-lispsmos-expression (cadr prop))))
            ('point-size (list 'pointSize (compile-lispsmos-expression (cadr prop))))
            ('point-style (list 'pointStyle (symbol->string (cadr prop))))

            ('fill-opacity (list 'fillOpacity (compile-lispsmos-expression (cadr prop))))
            ('fill (list 'fill (cadr prop)))
            ('lines (list 'lines (cadr prop)))

            ('show-label (list 'showLabel (cadr prop)))
            ('label (list 'label (cadr prop)))
            ('label-orientation (list 'labelOrientation (cadr prop)))
            ('label-size (list 'labelSize (cadr prop)))
            ('suppress-text-outline (list 'suppressTextOutline (cadr prop)))
        )
    ) display-properties))
)

(define (get-image-properties . image-properties)
    (flatten (map (lambda (prop)
        (match (car prop)
            ('center (list `center (compile-lispsmos-expression (cadr prop))))
            ('width (list `center (compile-lispsmos-expression (cadr prop))))
            ('height (list `center (compile-lispsmos-expression (cadr prop))))

            ('image-url (list `image_url (cadr prop)))
            
            ('draggable (cadr prop))
            ('foreground (cadr prop))
            ('name (cadr prop))
        )
    ) image-properties))
)





(define (compile-lispsmos-expression-list expr folder-name folder-id)
    (foldl (lambda (expression index expression-list) 
        (append expression-list  
            (cond
                ((eq? (car expression) 'folder) (append (list (hash
                    'id (number->string index)
                    'type "folder"
                    'title (if (eq? folder-name "") (caar (cdr expression)) 
                            (string-append folder-name "/" (caar (cdr expression))))
                    'collapsed (cadr (car (cdr expression)))
                    ))
                    (compile-lispsmos-expression-list 
                        (cddr expression)
                        (if (eq? folder-name "") (caar (cdr expression)) 
                            (string-append folder-name "/" (caar (cdr expression))))
                        (number->string index)
                    )
                ))
                (else (list 
                    (hash-union (cond 
                    ((eq? (car expression) 'image) 
                        (apply get-image-properties (cddr expression)))

                    ((eq? (car expression) 'display) (hash-union (hash
                        'hidden #f
                        'type "expression"
                        'latex (compile-lispsmos-expression (cadr expression))
                        'id (number->string index))
                        (apply hash (apply get-graph-display-properties (cddr expression)))))

                    ((eq? (car expression) 'note) (hash
                        'type "text"
                        'id (number->string index)
                        'text (cadr expression)))

                    (else (hash 
                        'hidden #t
                        'type "expression"
                        'latex (compile-lispsmos-expression expression)
                        'id (number->string index)))
                    )
                    (if (eq? folder-name "") (hash) (hash 'folderId folder-id))
                    )
                ))
               
        )
        )
    ) (list) expr (sequence->list (in-range (length expr)))))




(define (compile-lispsmos expr)
    (jsexpr->string 
        (hash
            'expressions (hash
                'list (compile-lispsmos-expression-list expr "" 0)
            )
            'version 9
            'randomSeed "f8731634d5d57a05dabd714121ac9b91"
            'graph (hash
                'viewport (hash
                    'xmin -10
                    'xmax 10
                    'ymin -10
                    'ymax 10
                )
            )
        )
    ))


(provide compile-lispsmos)