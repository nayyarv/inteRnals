# inteRnals

R was first written as an open source implementation of Bell's S language at Auckland Uni back in 1997 (Hadley went there from 1999-2004) with work starting in 1992. Statistical computing was primarily closed source at this time with SAS, SPSS and S/Splus and even Ross Ihaka and Robert Gentleman initally considered making R a product instead of a free open source language, so we should be glad that this ended up better than expected. Comparing R and Splus with Octave and Matlab, it's quite possible that R would never have reached the popularity it enjoys today. In fact without R, it's quite possible to imagine even fewer data scientists coming from a mathematical background, and without Hadley, it's quite possible to imagine R remaining a pure domain of university and research instead of it's current usage in industry too.

R is combination of Scheme and S. Scheme is a general purpose programming language and S was the statistical language with the flexibility to make doing statistics easy. The mix of imperative (change state with statements - think a[1] <- 3) and functional styles (change state only via functions apply(a, sum)) is primarily from Scheme, while S gives us a lot of the syntax doing with vector operations and formulas. Modern day R syntax owes more to S than Scheme, but a lot of the thinking behind Scheme shows up in R. S scripts will run almost unmodified in R, that's how much the syntax was borrowed. This mixed form of imperative and functional has been a clear winner in modern day high level languages, best espoused by Python and R, but also a raft of other languages. Another major innovation at the time (that now seems a bit obvious) was that R&R realised the power of having an external package system and CRAN was born along with the language were released in early 1997 and later released to the GNU later that year. The first stable release (1.0) came out in 2000 and it 2002 it got S4 methods. We're currently on 3.5 as of 2018.

## What is this About?

1. A Brief History of R
2. A mostly esoteric look into Rlang from a language design. This includes things like
    1. Is R pass by value or pass by reference
    2. How does R look after memory?
    3. An introduction to scoping and closures.
    4. Lazy Eval to quosures
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
In the above example, the `a` variable is refrred to by 4 other variables. It's reference count is 5, but R thinks it's only 3. This is a more concrete proof of the above, once R's NAM count goes to 2, it can never decrement. R's garbage collector has to work pretty hard as a result.


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

### R and Memory

R is an interpreted language in which the user doesn't need to deal with memory management. Ths



## No Scalar Values

## Weak Primitives and Generics

Have you ever wondered why RCpp is so prevalent among so many R packages. Surely most of them aren't doing anything so vital that can't be done in base R quickly enough. 



## Pass by Value 

R uses a "copy on modify" functionality, which is equivalent to "call by value" for all intents and purposes. Copy on modify allows for lazy evaluation for example and for dplyr syntax (quosures) which can be quite elegant and is slightly more efficient than simple call by value. Note that copy on modify can be implemented efficiently as it is in Clojure, but this not the case in R. 

Copy on modify is somewhat intelligent - for example, selecting a column from an input dataframe doesn't actually result in the whole vector being recreated. Here the number after @ is the memory location so we can see what R is doing.

```R
> nm = 10^7
> ts = tibble(a=runif(nm), b=runif(nm), c = runif(nm))
# ts is ~ 230 MB, slow. View and default print is really slow 
# (tibbles are much better here with significant performance improvements over data.frames)

> col2 = select(ts, -n)
# very quick, this is a reference to the data, no more data has been allocated.

> .Internal(inspect(ts)) 
@180f42e08 19 VECSXP g1c3 [OBJ,MARK,NAM(3),ATT] (len=3, tl=0)
  @186c4c000 14 REALSXP g1c7 [MARK,NAM(3)] (len=100000000, tl=0) 0.798401,0.280968,0.752619,0.574027,0.242734,...
  @1b673d000 14 REALSXP g1c7 [MARK,NAM(3)] (len=100000000, tl=0) 0.0871109,0.389349,0.668556,0.764266,0.106214,...
  @1e622e000 14 REALSXP g1c7 [MARK,NAM(3)] (len=100000000, tl=0) 0.0947341,0.783731,0.417293,0.0217895,0.343249,...
...
> .Internal(inspect(col2)) 
@14efae908 19 VECSXP g0c2 [OBJ,NAM(3),ATT] (len=2, tl=0)
  @1b673d000 14 REALSXP g1c7 [MARK,NAM(3)] (len=100000000, tl=0) 0.0871109,0.389349,0.668556,0.764266,0.106214,...
  @1e622e000 14 REALSXP g1c7 [MARK,NAM(3)] (len=100000000, tl=0) 0.0947341,0.783731,0.417293,0.0217895,0.343249,...
...
> col2[1,1] = 1 
# slow, upon modification, this is now a copy and slow operation.
> .Internal(inspect(col2)) 
@12468a6c8 19 VECSXP g1c2 [OBJ,MARK,NAM(3),ATT] (len=2, tl=0)
  @215d1f000 14 REALSXP g0c7 [] (len=100000000, tl=0) 3,0.389349,0.668556,0.764266,0.106214,...
  @1e622e000 14 REALSXP g1c7 [MARK,NAM(3)] (len=100000000, tl=0) 0.0947341,0.783731,0.417293,0.0217895,0.343249,...
...
> ts[1,]=1
> .Internal(inspect(ts))
@123b82cd8 19 VECSXP g1c3 [OBJ,MARK,NAM(3),ATT] (len=3, tl=0)
  @3043d4000 14 REALSXP g1c7 [MARK,NAM(3)] (len=100000000, tl=0) 1,0.280968,0.752619,0.574027,0.242734,...
  @333ec5000 14 REALSXP g1c7 [MARK,NAM(3)] (len=100000000, tl=0) 1,0.389349,0.668556,0.764266,0.106214,...
  @245810000 14 REALSXP g0c7 [NAM

``` 

When we subselect, we simply reference the original memory addresses. When we modify a single cell, that entire column is recreated as we can see by the changed memory address. When we modify an entire row, all the sub columns are modified. R primitives can be considered to be immutable in general. In a list or data frame, each primitve inside the list is considered immutable and when we write code that would mutate such a primitive, a new one is recreated in it's place. Creating a new list from an old list, doesn't recreate the objects it contains, a new list is created from scratch, but the underlying objects are shared between lists. Again, because of the immutability, changing one value in one list will not be reflected back to the other list. This is mostly a good protective mechanism with some optimisation, but this falls short in some areas, such as slicing which will copy the data.

Where does this become a problem?

R is a functional and imperative mixed language, much like Python. In pure functional languages, one has the guarantee of immutability to allow for a lot of optimisations, which fall a bit short in R's approach of copy on modify. Pass by reference may have unintended side-effects but in contrast, allows for more efficient code to be written in contrast.

### Code Design 




### And Big Data





## 1 indexing

Now, put your hand up, how often does the indexing actually matter that much in R? In fact, in higher level languages, the amount of time you index is somewhat rare and the 1 indexing doesn't really matter too much.


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


### The Problems

R has gone through a lot of development and the language today, is in far better shape than it was in 2012 which is when most of the critiques of R, such as aRgh, R inferno and even Ross Ihaka suggesting that we should step away from R as a language and start again. The fact that Python came out of basically nowhere to overtake R is a testament to this, and the surprisingly fast growth of Julia is also a testament to variety of choice out there and the fact that R doesn't have very many converts to the language (outside MATLAB, SAS or SPSS)

R has a number of implementations besides the GNU version. Radford Neal of UToronto has released pqR (pretty quick R) which supports multi-threading. Revolution Analytics/Microsoft has their own version too, with similar claims including improved stability. Renjin and Riposte are other implementations, but are significantly less well known. The GNU R we all use is by far the most popular, but the claims of the alternative developers is interesting - Radford Neal complains about the poor design of R's Syntax and Bob Carpenter of STAN discusses how he developed the syntax to be like R without it's failings, and the implication of stability from Revolution R is a bit concerning. Even Hadley uses language that reveals his concerns over the R language on occassion, and the man has not been invited to be on R core committers group despite all he's done for the language.

R as a language, does indeed have many flaws. Radford Neal has written endlessly about problems with R, submitted efficiency patches to the core language (none appear to have been merged into GNU R and resulted in it's merge). Ross Ihaka, one of the OG R developers [has written on his concerns with R's language in the past, suggesting starting over again](https://xianblog.wordpress.com/2010/09/13/simply-start-over-and-build-something-better/), though it was years ago. Christian Robert, (Xian's Og) has repeated these concerns - and in fact some of his patches have made it into Revolution's R and not GNU R. The attitude of computer scientists to R should have us respond with questions and thoughts instead of the defensiveness I see in the community. One major thing that we need to do is separate our feelings of the R base language and the R packages. It's my opinion that the R developer ecoystem deserves a better language. Part of me feels the reason that every single package seems to use RCpp to avoid writing too much R.

## Scoping and Namespaces

Loading a package does not allow you to choose which functions you want from that package. When you need `quo` or `quos` from `rlang`, you need to do `library(rlang)` and the entire namespace is loaded into your session. You can't choose which parts of the code you want - you are at the mercy of the package author and what they decide. Using `requireNamespace` prevents global namespace pollution, but if you put all your functions into a single file and only need one, you don't have any elegant method to attach functions from a single source file. You have to create a whole package and then only do you get the benefits of a namespace. 

```R
library(devtools)
install("~/path/to/my/my_external_package")
# now every function is available as per Namespace
# also, install takes forever for even a single R file
```

```python
from my_external_file import only_useful_function
# equivalent to above R
from my_external_file import *
```

### Why Do Namespaces Matter?

Namespaces are extremely useful when writing large segments of code. In python doing the `from package import *` is considered bad style because it means that the person reading the code has no idea which function is being run with a single look of the code. Seeing `np.sqrt` or `pd.sqrt` makes it very easy to tell where exactly the function came from. For someone unfamiliar with R or the packages being used, the functions are not obvious where they came from at first glance. Even inbuilt functions like dim and state can easily be overshadowed this way and this makes for reading another person's R code a truly horrible experience.

Furthermore, certain words have a lot of use in various R packages. If you use a few different packages, I have to be familiar with them to work out where a function came from. `summarize` shows up a few times for example, if I mask it by mistake, without an interactive terminal, it can be very difficult to tell why `plyr`'s summarize doesn't seem to be working as expected. Import order matters tremendously here and it really shouldn't.

This is very important when it comes to maintainability of code. I've specialised in Continuous Deployment of various Data Science approaches and this code needs readability and ownership to have this kind of deployment. If you're not using a package like `drake`, it's really easy to have code and reports go out of sync, and if you're trying to build your team's business IP on R, coding without namespaces makes it very difficult! There are other languages that have this issue, i.e. C with it's headers, but as a statically typed language, you have a lot of checks and the function signature allows the correct usage of two different functions. 

### How to be Better?

R doesn't encourage us to use the `namespace::function` syntax, which is a shame in my opinion, but also the use of `library` ensures your global namespace is polluted anyway. I strongly suggest using `requireNamespace` at all times (not just when writing your own package), as this doesn't ever pollute the global namespace and allows you to pull whatever function you wish more explicityl

```r
> search()
    [1] ".GlobalEnv"        "package:stats"     "package:graphics"
    [4] "package:grDevices" "package:utils"     "package:datasets"
    [7] "package:methods"   "Autoloads"         "package:base"
> requireNamespace("rlang")
> rlang::quo
    function (expr)
    {
        enquo(expr)
    }
    <bytecode: 0x7fd1de8873b0>
    <environment: namespace:rlang>
> quo
    Error: object 'quo' not found
> search()
    [1] ".GlobalEnv"        "package:stats"     "package:graphics"
    [4] "package:grDevices" "package:utils"     "package:datasets"
    [7] "package:methods"   "Autoloads"         "package:base"
```

If you have a long winded package, `var = loadNamespace("longNamedPackage")` allows you to remap the name to something shorter and access as a variable instead of a namespace, however Hadley doesn't encourage it, and I don't have the authority to contradict Hadley. I do want to say that nearly every other more modern programming language of note makes heavy use of explicit namespaces (Python, Go, Julia, C++, Haskell) so I think that's a good enough reason for R users to consider using namespace's more carfully and explicitly.

### Import Mechanics

You're at the mercy of package developers and other co-workers whose functions you depend on. Again, it's very easy for package developers to do an in function import - this makes sense if they only require it for one function and so don't want to label it as a required dependency. So they import the package they want in the single function that uses it.

```R
> search()
    [1] ".GlobalEnv"        "package:stats"     "package:graphics"
    [4] "package:grDevices" "package:utils"     "package:datasets"
    [7] "package:methods"   "Autoloads"         "package:base"
> quo
    Error: object 'quo' not found
> hi
function(){library(rlang)}
> hi()
> quo
    function (expr)
    {
        enquo(expr)
    }
    <bytecode: 0x7fc7773d7908>
    <environment: namespace:rlang>
> > search()
 [1] ".GlobalEnv"        "package:rlang"     "package:stats"
 [4] "package:graphics"  "package:grDevices" "package:utils"
 [7] "package:datasets"  "package:methods"   "Autoloads"
[10] "package:base"
```

And boom, rlang is now loaded into your global space. All the more reason to get into the habit of using `requireNamespace` by default. Any variables created in a function are only scoped to that function, but any uses of `library` go global, which I think is too easy to do. 