nm = 10^6

tsgen <- function(num=nm){
  return(tibble(a=runif(nm), b=runif(nm), c = runif(nm)))
}

ts =tsgen()

a  = list(runif(nm), runif(nm))
.Internal(inspect(a))

addField <- function(lst){
  n = length(lst)
  lst[[n+1]] <- runif(nm)
  lst
}
b = addField(a)
.Internal(inspect(b))

c = list(tsgen(), tsgen())
.Internal(inspect(c))
c[[2]][1,1]=3
.Internal(inspect(c))


library(pryr)
idt = function(obj) {address(obj)}
idins = function(obj) {.Internal(inspect(obj))}
a = c(1,2,3)
address(a)
idt(a)
.Internal(inspect(a))
idins(a)


#pipe fun
`%pp%` = function(lhs, rhs){
  
  rhs(lhs)
}

93 %pp% adder


## frame fuckery

addToGlobal = function(k, val){
  fr= parent.frame()
  assign(k, val, fr)
}

herpyderp

addToGlobal("herpyderp")

herpyderp


## substitute magic

subquot = function(arg){
  substitute(arg)
}

subquot('new' & 3)
