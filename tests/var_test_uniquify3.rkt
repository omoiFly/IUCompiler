(let ([x 41]) 
    (let ([y x]) 
        (+ x 
            (let ([x (+ x y)]) 
                (+ x y)))))
