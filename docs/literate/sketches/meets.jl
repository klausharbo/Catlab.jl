# # Meets
#
#md # [![](https://img.shields.io/badge/show-nbviewer-579ACA.svg)](@__NBVIEWER_ROOT_URL__/generated/sketches/Partitions.ipynb)
#
# Our first example of a concept defined by a universal mapping property is a meet respectively join.
# 

# The first step is our Catlab imports
using Core: GeneratedFunctionStub
using Test

using Catlab, Catlab.Theories, Catlab.CategoricalAlgebra, Catlab.CategoricalAlgebra.FinSets
using Catlab.Present
using Catlab.Graphics
using Catlab.Graphics.Graphviz

import Catlab.Theories: compose
using DataStructures

# # Defining some basic preorders

@present P(FreeSchema) begin
  (A,B,C,D)::Ob
  f::Hom(A, B)
  g::Hom(A, C)
  h::Hom(B, D)
  k::Hom(C, D)
end

# We can draw a picture of our preorder as a Hasse Diagram.

to_graphviz(P)

# It will be convenient to program with our preorders based on the Hasse Diagram
# represent as a labeled graph so we convert the Presentation{Schema, Symbol} into a FreeDigram.
# FreeDiagrams are implemented as an ACSet which you can think of as an in-memory database.
# ACSets are a key feature of Catlab that allow you to represent many data structures in a
# common framework.

g = FreeDiagram(P)

# To give ourselves a graph-like API for Hasse Diagrams, we define parents and children.

parents(g, y::Int) = subpart(g, incident(g, y, :tgt), :src)
children(g, x::Int) = subpart(g, incident(g, x, :src), :tgt)

# We can compute upsets with breadth first search.

function bfs(g, x::Int, f=children)
  explored = falses(nparts(g, :V))
  explored[x] = 1
  q = Queue{Int}()
  enqueue!(q, x)
  while !isempty(q)
    v = dequeue!(q)
    S = f(g,v)
    map(filter(s -> !explored[s], S)) do s
      enqueue!(q, s)
    end
    explored[S] .= true
  end
  return findall(explored)
end

# The upset of a preorder element is all the elements that come after it in the preorder.

upset(g,x) = bfs(g,x,children)

# The downset is the dual notion, which we compute by reversing the role of children and parents.

downset(g,x) = bfs(g,x,parents)

upset(g, 1)

# We can use upsets to define the less than or equal two relation implied by any Hasse Diagram

function leq(g::FreeDiagram, x::Int, y::Int)
  return y in upset(g, x)
end

# ### Exercise 1
# Define a more efficient algorithm for checking whether two elements satisfy the leq relation.

# Multiple dispatch allows us to overload the leq function with another method for symbols.

function leq(g::FreeDiagram, x::Symbol, y::Symbol)
  leq(g, incident(g, x, :ob), incident(g, y, :ob))
end


# the meet of two elements is the smallest element in the intersection of their upsets

function meet(g::FreeDiagram, x::Int, y::Int)
  U = upset(g, x) ∩ upset(g,y)
  minima(g, U)
  return minimum(g, U)
end

function meet(g::FreeDiagram, x::Symbol, y::Symbol)
  meet(g, incident(g, x, :ob), incident(g, y, :ob))
end

# assuming that U is an upset, the minima are those elements whose parents are disjoint from the upset.

function minima(g::FreeDiagram, U::Vector{Int})
  X = Set(U)
  minima = filter(U) do x
    Pₓ = parents(g, x) ∩ X
    length(Pₓ) == 0
  end
  return minima
end

function hasbottom(g::FreeDiagram, xs::Vector{Int})
  length(minima(g, xs)) == 1
end

function minimum(g::FreeDiagram, xs::Vector{Int})
  m = minima(g, xs::Vector{Int})
  if length(m) == 1
    return m[1]
  end
  if length(m) > 1
    all_iso = all(m) do a
      Uₐ = upset(g, a) 
      a_le_allb = all(m) do b
        b in Uₐ
      end
      return a_le_allb
    end
    if all_iso 
      return  m[1]
    end
  end
  return nothing
end

# From the definition of minimum, you can see that when you want to do many leq queries
# in sequence, you can reuse the upsets that you compute with bfs. This is a place where
# mathematical abstractions don't work well with the operational needs of computer programming.
# In a mathematical definition you can define x ≤ y as y ∈ upset(x), but in programming, that is
# inefficient when you want to check a property like for all y in Y, x ≤ y. Programming requires
# you to reason about not only the correctness of the code, but also the performance. Much of the
# complexity of software engineering comes from the fact that computational performance requires
# the programmers to break down their clean abstractions to optimize the code.

# ### Exercise 2
# If you wanted to perform many x ≤ y queries in a loop, you might want to 
# precompute the matrix L where L[i,j] = 1 if and only if i ≤ j in the preorder P.
# Implement an algorithm that performs this computation in O(V⋅E) time where V is the number of
# elements in P and E is the number of edges in the corresponding FreeDiagram.

# ## Testing it out

# Let's make sure we get the answers that we expect.

using Test
@testset "Upsets" begin
  @test upset(g, 3) == [3,4]
  @test upset(g, 2) == [2,4]
  @test upset(g, 1) == [1,2,3,4]
  @test upset(g, 4) == [4] 
end
@testset "Downsets" begin
  @test downset(g, 3) == [1,3]
  @test downset(g, 2) == [1,2]
  @test downset(g, 4) == [1,2,3,4]
  @test downset(g, 1) == [1] 
end

@testset "Meets" begin
  @test meet(g, 2,3) == 4
  @test meet(g, 1,2) == 2
  @test meet(g, 3,4) == 4
  @test meet(g, 1, 4) == 4
  @test meet(g, 1, 1) == 1
  @test meet(g, 2, 2) == 2
end

# ## Another Example:

@present P(FreeSchema) begin
  (A,B,C,D, E)::Ob
  f::Hom(A, B)
  g::Hom(A, C)
  h::Hom(B, D)
  k::Hom(C, D)
  l::Hom(B, E)
end

# Which can be viewed as a picture:

to_graphviz(P)

# Or, as tables:

g = FreeDiagram(P)

# ### Test suite

@testset "Meets2" begin
  @test meet(g, 2,3) == 4
  @test meet(g, 1,2) == 2
  @test meet(g, 3,4) == 4
  @test meet(g, 1, 4) == 4
  @test meet(g, 1, 1) == 1
  @test meet(g, 2, 2) == 2
  @test meet(g, 3, 5) == nothing
  @test meet(g, 2, 5) == 5
end

# ### Exercise 3
# Make bigger preorders to test corner cases in the above code. 
# If you find an example that breaks these implementations, please report it.
 

# ### Exercise 4
# Implement the dual constructions for joins.