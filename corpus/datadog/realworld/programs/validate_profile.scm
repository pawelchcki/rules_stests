(define capture (read))

(if (eq? validation-mode 'exact)
    (validate-profile profile scenario-name capture (cons 'exact scenario-shape))
    (validate-profile profile scenario-name capture 'contract))
