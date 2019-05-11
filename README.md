Note: An incomplete summary of the talk

- [PDF Slides](presentation.pdf)
- [HTML Slides](presentation.html)

# inteRnals

R was first written as an open source implementation of Bell's S language at Auckland Uni back in 1997 (Hadley went there from 1999-2004) with work starting in 1992. Statistical computing was primarily closed source at this time with SAS, SPSS and S/Splus and even Ross Ihaka and Robert Gentleman initally considered making R a product instead of a free open source language, so we should be glad that this ended up better than expected. Comparing R and Splus with Octave and Matlab, it's quite possible that R would never have reached the popularity it enjoys today. In fact without R, it's quite possible to imagine even fewer data scientists coming from a mathematical background, and without Hadley, it's quite possible to imagine R remaining a pure domain of university and research instead of it's current usage in industry too.

R is combination of Scheme and S. Scheme is a general purpose programming language and S was the statistical language with the flexibility to make doing statistics easy. The mix of imperative (change state with statements - think `a[1] <- 3`) and functional styles (change state only via functions `apply(a, sum))` is primarily from Scheme, while S gives us a lot of the syntax doing with vector operations and formulas. Modern day R syntax owes more to S than Scheme, but a lot of the thinking behind Scheme shows up in R. S scripts will run almost unmodified in R, that's how much the syntax was borrowed. This mixed form of imperative and functional has been a clear winner in modern day high level languages, best espoused by Python and R, but also a raft of other languages. Another major innovation at the time (that now seems a bit obvious) was that R&R realised the power of having an external package system and CRAN was born along with the language were released in early 1997 and later released to the GNU later that year. The first stable release (1.0) came out in 2000 and it 2002 it got S4 methods. We're currently on 3.5 as of 2018.

## What is this About?

1. A Brief History of R
2. A mostly esoteric look into Rlang from a language design. This includes things like
    1. Is R pass by value or pass by reference
    2. How does R look after memory?
    3. An introduction to scoping and closures.
    4. Lazy Eval to Quosures
4. Summer of 2013

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

## The Language

### Mutability and Pass by Value/Reference

Pass by Value means that the variables are copied when passed to a function, and Pass by Reference means that the underlying object is passed to be modified. C is pass by copy and Python is pass by reference. 

The answer is neither, R is something known as copy on modify. What does this mean? I'm also going to use `.Internal(inspect(obj))` to illustrate. Hadleyverse also has a library, `pryr` that helps along, but when trying to peel back how a language works, it's a good idea to remain within the base language as much as possible.

NOTE: RStudio interferes a bit with R, so run these in a detached terminal. The memory addresses have been truncated to make the output cleaer

```R
> a = c(1,2,3)
> .Internal(inspect(a))
@fadb88 14 REALSXP g0c3 [NAM(1)] (len=3, tl=0) 1,2,3
```

In the above, the first field is the address (the hex value prefixed with @), the `NAM(n)` field refers to the number of references a certain variable has (more on this later) and then some other metadata, such as type is included. Let's modify this!


```R
> a[1] = 2
> .Internal(inspect(a))
@fadb88 14 REALSXP g0c3 [NAM(1)] (len=3, tl=0) 2,2,3
```

Here, we see that the address field has remained unchanged. The object `a` has been mutated! This is where the reference counter `NAM(1)` comes handy, since R knows that only variable `a` is pointing to that memory location, we can mutate. So then how does R handle copies?

```R
> a = c(1,2,3)
> .Internal(inspect(a))
@fad9f8 14 REALSXP g0c3 [NAM(1)] (len=3, tl=0) 1,2,3
> b = a
> .Internal(inspect(b))
@fad9f8 14 REALSXP g0c3 [NAM(2)] (len=3, tl=0) 1,2,3
> a[1] = 2
> .Internal(inspect(a))
@fad868 14 REALSXP g0c3 [NAM(1)] (len=3, tl=0) 2,2,3
> .Internal(inspect(b))
@fad9f8 14 REALSXP g0c3 [NAM(2)] (len=3, tl=0) 1,2,3
```

Here we see how the NAM and address interact. We've created `a` as before, but this time, we've set `b=a`. Instead of copying theoretically large vectors, R simply points them to the same underlying data and updates the reference count. We now see that `NAM` has been updated to 2. Now when we try and update `a`, R knows it's not safe to mutate the existing vector since another vector depends on it. R then creates a copy of the old data, updates it to it's new value and this shows in the changed internals of `a`, while `b` remains unchanged.

In fact, we see a slight inefficiency here - `b`'s NAM count should be 1 now since `a` no longer points to the same data. We'll come back to this later, but the takeaway is that R doesn't keep a proper count - the NAM value is either 1 or greater than 1. 

How does this interact with functions? 

```R
> a = c(1,2,3)
> blnk = function(obj){}
> .Internal(inspect(a))
@7fd2015f8068 14 REALSXP g0c3 [NAM(1)] (len=3, tl=0) 1,2,3
> blnk(a)
NULL
> .Internal(inspect(a))
@7fd2015f8068 14 REALSXP g0c3 [NAM(1)] (len=3, tl=0) 1,2,3
```

In this example, a function that doesn't do anything, doesn't change anything. This ties into the section on lazy evaluation here. This is expected, so let's see what happens when we do something simple (like get the first value)

```R
> a = c(1,2,3)
> first = function(obj){obj[1]}
> .Internal(inspect(a))
@7fd2015f7d98 14 REALSXP g0c3 [NAM(1)] (len=3, tl=0) 1,2,3
> first(a)
[1] 1
> .Internal(inspect(a))
@7fd2015f7d98 14 REALSXP g0c3 [NAM(3)] (len=3, tl=0) 1,2,3
```

Huh, the takeaway here is that a function call results in the NAM count going to 3. However, in this case, the a variable has not been mutated, simply a value has been extracted. It turns out that any function that evaluates the object will increment the refs of the variable. This is a simple way to ensure that a function cannot cause side-effects!

However, since R does not distinguish between the reference count when the reference count is > 1, R cannot decrement the count safely once the count >= 2. By incrementing the count when passing it into the function, it makes sense to decrement the count once outside the function. `a` is the only reference, but since R cannot distinguish between 2 references and 100 references safely

```R
> a = c(1,2,3)
> .Internal(inspect(a))
@7f877050bb88 14 REALSXP g0c3 [NAM(1)] (len=3, tl=0) 1,2,3
> b = a
> d = a
> e = a
> f = a
> .Internal(inspect(a))
@7f877050bb88 14 REALSXP g0c3 [NAM(3)] (len=3, tl=0) 1,2,3
```
In the above example, the `a` variable is referred to by 4 other variables. It's reference count is 5, but R thinks it's only 3. This is a more concrete proof of the above, once R's NAM count goes to 2, it can never decrement. R's garbage collector has to work pretty hard as a result.


Expanding this to `data.frames` and `lists`, we can see 

```R
> a = c(2,2,3)
> b = c(2,2,3)
> .Internal(inspect(a))
@2898378 14 REALSXP g0c3 [NAM(1)] (len=3, tl=0) 2,2,3
> .Internal(inspect(b))
@2157408 14 REALSXP g0c3 [NAM(1)] (len=3, tl=0) 2,2,3


> lst = list(a, b)
> .Internal(inspect(lst))
@2acbcc8 19 VECSXP g0c2 [NAM(1)] (len=2, tl=0)
  @2898378 14 REALSXP g0c3 [NAM(3)] (len=3, tl=0) 2,2,3
  @2157408 14 REALSXP g0c3 [NAM(3)] (len=3, tl=0) 2,2,3


> tb = tibble(a=a, b=b)
> .Internal(inspect(tb))
@28672c8 19 VECSXP g0c2 [OBJ,NAM(2),ATT] (len=2, tl=0)
  @2898378 14 REALSXP g0c3 [NAM(3)] (len=3, tl=0) 2,2,3
  @2157408 14 REALSXP g0c3 [NAM(3)] (len=3, tl=0) 2,2,3
ATTRIB:
  @2e2bbb0 02 LISTSXP g0c0 []
  ... # there is a lot of random stuff in this tibble
```
The first number is the address of the container object, while the next two are the addresses of the underlying data. Here, we're not copying the data into the new structure, we're simply copying references to the data. In many ways, `lists` and `tibbles`/`data.frames` behave identically from a memory perspective. Now what happens when we drop a column from `tb`, by modifying it directly.

```R
> lst[[2]] = NULL
> .Internal(inspect(lst))
@27edc90 19 VECSXP g0c1 [NAM(1)] (len=1, tl=0)
  @2898378 14 REALSXP g0c3 [NAM(3)] (len=3, tl=0) 2,2,3
  ...
```

Despite the list having a NAM count of 1, it actually changes it's memory location when we drop a column. This is an example where R does have edge cases. If you changed `lst[[2]]` to another vector though, it'd have mutated in place. Adding new fields also causes a copy to be made. 

Tibbles and `data.frame`s follow similar rules - columns are independent vectors and adding or dropping columns result in the  

The memory location of `lst` has changed, as has it's contents. The `b` vector is nowhere to be found, as expected, but `a` still retains it's memory location. This shows us how objects in R aren't actually mutable - to drop a column, we create a new tibble and fill it with the relevant references. In this particular use case, we would also free the previous memory usage of the previous tibble to be a bit more efficient. Since most of the data, the columns, are retained across tibble transforms, this actually a quick-action for most part. 

One thing to note here is that R's implementation of copy-on-modify is not the most efficient. In the above, dropping the b column doesn't actually need to create a whole new tibble. Imagine if you had 500 columns instead of 2, dropping a column required a tibble to be recreated and 499 column references and meta-attibs to be copied over. There are alternatives, but discussing them woulod take a while.

Additionally, you should have noticed that the columns are basically independent of each other to further drive this home,

```R
> tb = tibble(a=a, b=b)
> .Internal(inspect(tb))
@14c8e5188 19 VECSXP g0c2 [OBJ,NAM(3),ATT] (len=2, tl=0)
  @1113c8428 14 REALSXP g0c3 [MARK,NAM(3)] (len=3, tl=0) 2,2,3
  @180892b48 14 REALSXP g0c3 [MARK,NAM(3)] (len=3, tl=0) 2,2,3
> tb[1,1] = 3
> .Internal(inspect(tb))
@14cefc748 19 VECSXP g0c2 [OBJ,NAM(3),ATT] (len=2, tl=0)
  @17f37b3f8 14 REALSXP g0c3 [NAM(3)] (len=3, tl=0) 3,2,3
  @180892b48 14 REALSXP g0c3 [MARK,NAM(3)] (len=3, tl=0) 2,2,3
```
In the above example, the modification of the first element has required a new tibble to be created, the unchanged row to have it's reference copied as is, and the first column to be recreated with a new value in it's 1st index. This is also why column manipulation tends to be much faster than row manipulation.

#### The Pros

Nothing being mutable makes the code much safer. You cannot cause side-effects this way. In python, it's quite possible to mutate an object in a function which can cause errors downstream. This copy-on-modify functionality is likely designed to ape purely functional languages which are always immutable, and Clojure is another language that shares a common ancestor that uses the same model, and it has much greater performance in comparison to R.

Copy on modify is better than pass by value in that you don't ever need to worry that using functions causes massive overhead. This behaviour always holds, which means that using functions should never reduce the performance of your code.

#### The Cons

Mutability can lead to improved performance as mentioned in an example before. Copy on modify, while providing a safe experience to the novice user, does limit the possibility for an advanced user. However, RCpp allows a user to modify in place, so you don't also get a guaranteed experience either.

```R
> d = c(1,2,3)
> .Internal(inspect(d))
@17e9465a8 14 REALSXP g0c3 [NAM(3)] (len=3, tl=0) 1,2,3
> cppFunction('
+   void doubC(NumericVector x) {
+   int n = x.size();
+   for(int i = 0; i < n; ++i) {
+     x[i] = x[i]*2;
+   }
+ }
+')
> doubC(d)
> .Internal(inspect(d))
@17e9465a8 14 REALSXP g0c3 [NAM(3)] (len=3, tl=0) 2,4,6
```

Lists are very efficient when they're small and contain large objects. Adding or removing to them is not too compicated and not too inefficient. In fact lists have `O(n)` complexity for insertion and deletion for this reason. This efficiency breaks down when lists are large, doubly so when used for primitives, and for this reason this limits their usefulness. Using for loops and building up a list is non-idiomatic R, but this is sometimes unavoidable. For instance, parsing a csv into a data frame requires code to loop through lines, keep track of various columns and combine at the end. R's existing models simply don't allow an efficient way to parse a csv in pure R, you are forced to write the parsing logic in C (`scan`). This is not the case in python in comparison.



## Consistency > Syntactic Sugar

### What is the difference between `<-` and `=`?

```r
x<-y
x < -y
```

### Quosures, tidyeval, and programming with `dplyr`

## Advanced Programming

### Object Orientation

### Package Writing

Even when writing a package, Namespace files are fiendishly difficult to write



## Docstrings


## Summer of 2013

R has gone through a lot of development and the language today, is in far better shape than it was in 2012 which is when most of the critiques of R, such as aRgh, R inferno and even Ross Ihaka suggesting that we should step away from R as a language and start again. The fact that Python came out of basically nowhere to overtake R is a testament to this, and the surprisingly fast growth of Julia is also a testament to variety of choice out there and the fact that R doesn't have very many converts to the language (outside MATLAB, SAS or SPSS)

R has a number of implementations besides the GNU version. Radford Neal of UToronto has released pqR (pretty quick R) which supports multi-threading. Revolution Analytics/Microsoft has their own version too, with similar claims including improved stability. Renjin and Riposte are other implementations, but are significantly less well known. The GNU R we all use is by far the most popular, but the claims of the alternative developers is interesting - Radford Neal complains about the poor design of R's Syntax and Bob Carpenter of STAN discusses how he developed the syntax to be like R without it's failings, and the implication of stability from Revolution R is a bit concerning. Even Hadley uses language that reveals his concerns over the R language on occassion, and the man has not been invited to be on R core committers group despite all he's done for the language.

R as a language, does indeed have many flaws. Radford Neal has written endlessly about problems with R, submitted efficiency patches to the core language (none appear to have been merged into GNU R and resulted in it's merge). Ross Ihaka, one of the OG R developers [has written on his concerns with R's language in the past, suggesting starting over again](https://xianblog.wordpress.com/2010/09/13/simply-start-over-and-build-something-better/), though it was years ago. Christian Robert, (Xian's Og) has repeated these concerns - and in fact some of his patches have made it into Revolution's R and not GNU R. The attitude of computer scientists to R should have us respond with questions and thoughts instead of the defensiveness I see in the community. One major thing that we need to do is separate our feelings of the R base language and the R packages. It's my opinion that the R developer ecoystem deserves a better language. Part of me feels the reason that every single package seems to use RCpp to avoid writing too much R.