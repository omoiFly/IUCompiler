(let ([x 41]) 
    (let ([y x]) 
        (+ x 
            (let ([x 1]) 
                (+ x y)))))
