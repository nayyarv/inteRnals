# inteRnals


## History

R's history can trace it's origin to two distinct languages. S and Scheme. Let's start with S first

### History of S

S was a statistical programming language developed in the 1970s at Bell Labs by John Chambers. It went through a few iterations, with it's 3.0 release in 1988 becoming the seminal version, being rewritten in C, adding OO concepts and becoming more of a programming language than an actual loose set of fortran bindings. It had another major release in 1998, v4.0 which mostly added better OO capabilities. This is where R's two methods or OO come from, the S3 and S4 releases of S.

While S was getting quite popular, Bell Labs licensed out exclusive implementation of S which was called S plus. In fact, S plus is fully compatible with R, the syntax is mostly unchanged, most of the changes aren't obvious when examining a piece of code.

### History of Scheme

Scheme is one of the dialects of Lisp, a hugely influential programming language that was actually defined purely in mathematical terms in 1958, mostly to show that purely functional languages are still Turing complete. Scheme took this mostly theoretical foundation and added the necessary parts to run on an actual computer and was a huge driver of popularity of functional langauges. 

LISP's most popular dialect is Clojure, while other dialects, like Common Lisp have influenced other very popular languages like Python, Ruby, Scala and Julia. Despite having never quite achieved success as a language, many of the languages inspired by it are very popular

### History of R

R is effectively a Scheme interpreter using S syntax. S was already very close to Scheme in many ways, it just hadn't really considered the implications in a way that Scheme's designers had. This made R a much more stable language than S from the outset, as it included garbage collection by default and better scoping rules which was the original inspiration for Ross Ihaka to start coding up R. 

R's other big innovation was to be released as open source. In an era where SPSS, SAS and S+ were paid software and open source was very much in it's infancy, this was a huge move, undoubtedly helped along by Bell Labs' woes (See Octave vs Matlab, octave was put together the same time as R, but never reached the same heights)