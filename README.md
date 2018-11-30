# Critical R

R, as a tool to be used in analysing data is fantastic. R+tidyverse makes data munging easy and the inbuilt statistical awareness of the language means you have fantastic results available with almost no work and the efforts of Hadley and Rstudio have made R extremely user friendly compared to what it's used to be. This is not a repudiation of R, but rather a gentle criticism of R as a language.

I don't consider myself a computer scientist or a programmer, but my chosen career has led me to do a lot of programming so I've picked up an understanding of the various paradigms of programming and lanugage design. The first language I learnt was C, before I ran away screaming on the introduction to linked lists and pointer arithmetc. I then moved on to Matlab and R and for a while, R was my strongest programming language. I picked up Python in my first internship, and it slowly became my programming language of choice, supplanting R quite quickly when possible. I've since picked up C++, Go, Haskell and Julia (though none at a strong/employable level) and my time programming in various other languages has given me a greater understanding of the shortcomings of other languages and I think even at a meetup about R, we should be able to provide introspection without being blinded. 

I'm not going to sing R's praises, that happens 10 months of the year. The goal of this talk, is to encourage those of you who program primarily in R to learn another language, those of you who think your workflows are subpar to try other methods and bring back new methods and ideas to R, maybe even a high quality package for R programmers worldwide. 


## Intro

R was first written as an open source implementation of Bell's S language at Auckland Uni back in 1997 (Hadley went there from 1999-2004) with work starting in 1992. Statistical computing was primarily closed source at this time with SAS, SPSS and S/Splus and even Ross Ihaka and Robert Gentleman initally considered making R a product instead of a free open source language, so we should be glad that this ended up better than expected. Comparing R and Splus with Octave and Matlab, it's quite possible that R would never have reached the popularity it enjoys today. In fact without R, it's quite possible to imagine even fewer data scientists coming from a mathematical background, and without Hadley, it's quite possible to imagine R remaining a pure domain of university and research instead of it's current mixed usage.

R is combination of Scheme and S. Scheme is a general purpose programming language and S was the statistical language with the flexibility to make doing statistics easy. The mix of imperative (change state with statements - think a[1] <- 3) and functional styles (change state only via functions apply(a, sum)) is primarily from Scheme. In fact R and Python share a common ancestor in Lisp which is why so much of the syntax and programming style seems so similar. S scripts will run almost unmodified in R, that's how much the syntax was borrowed. R&R realised the power of having an external package system and CRAN and the language were released in early 1997 and later released to the GNU later that year. The first stable release (1.0) came out in 2000 and it 2002 it got S4 methods for oo programming. We're currently on 3.5 as of 2018.

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

### Quosures, tidyeval, and programming with `dplyr`

## Advanced Programming

### Object Orientation

### Package Writing

Even when writing a package, Namespace files are fiendishly difficult to write



## Docstrings