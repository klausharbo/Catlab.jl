using Catlab
using Catlab.CategoricalAlgebra
using Catlab.Graphs
using Catlab.Graphs.BasicGraphs
using Catlab.Graphics
using Catlab.Graphics.Graphviz
using Catlab.Graphics.GraphvizGraphs
using Catlab.Graphs.PropertyGraphs
using Catlab.Theories
using Catlab.CategoricalAlgebra.CSets
#import Catlab.Graphics.Graphviz: to_graphviz, to_graphviz_property_graph
using Colors
draw(g) = to_graphviz(g, node_labels=true)

GraphvizGraphs.to_graphviz(f::ACSetTransformation; kw...) =
  to_graphviz(GraphvizGraphs.to_graphviz_property_graph(f; kw...))

function GraphvizGraphs.to_graphviz_property_graph(f::ACSetTransformation; kw...)
  pg = GraphvizGraphs.to_graphviz_property_graph(dom(f); kw...)
  vcolors = hex.(range(colorant"#0021A5", stop=colorant"#FA4616", length=nparts(codom(f), :V)))
  ecolors = hex.(range(colorant"#6C9AC3", stop=colorant"#E28F41", length=nparts(codom(f), :E)))
  hex.(colormap("Oranges", nparts(codom(f), :V)))
  for v in vertices(dom(f))
    fv = f[:V](v)
    set_vprops!(pg, v, Dict(:color => "#$(vcolors[fv])"))
  end
  for e in edges(dom(f))
    fe = f[:E](e)
    set_eprops!(pg, e, Dict(:color => "#$(ecolors[fe])"))
  end
  pg
end

println(Graphs.Graph)
println(typeof(Graphs.Graph))

generators(BasicGraphs.TheoryGraph)

to_graphviz(Catlab.Graphs.BasicGraphs.TheoryGraph)

# Constructing the Category of Graphs
#```
# # Graphs
# ########

# @present TheoryGraph(FreeSchema) begin
#   V::Ob
#   E::Ob
#   src::Hom(E,V)
#   tgt::Hom(E,V)
# end

# """ Abstract type for graphs, aka directed multigraphs.
# """
# @abstract_acset_type AbstractGraph <: HasGraph

# """ A graph, also known as a directed multigraph.
# """
# @acset_type Graph(TheoryGraph, index=[:src,:tgt]) <: AbstractGraph
# ```
#
#
# That is all we need to do to generate the functor category [TheoryGraph, FinSet].
# Catlab knows how to take a finitely presented category and generate all the data structures
# that you need to represent functors into FinSet and natural transformations between those functors.
# Note: the index=[:src, :tgt] keyword argument tells Catlab that you want to have an efficient index
# the preimages of those morphisms. in this example, we want to be able to find the incoming and 
# outgoing edges of a vertex in O(1) time.

# Creating some Graphs

# Once you have fixed the schema (aka indexing category or theory), you can make some instances.
# Catlab has a DSL for specifying instances of any schema. It is called `@acset`.
# In order to specify a Functor F=(F₀, F₁) into FinSet, you need to provide some data. 
#     1. For every A:Ob(C), you need F₀(A):FinSet
#     2. For every f:A→B, you need to specify a FinFunction F₁(f):F₀(A)→F₀(B)
# If the theory C has some equations, the data you provide would have to also satisfy those equations.
# The theory of graphs has no equations, so there are no constraints on the data you provide, 
# except for those that come from functoriality.

e = @acset Graphs.Graph begin
    V = 2
    E = 1
    src = [1]
    tgt = [2]
end

draw(e)

w = @acset Graphs.Graph begin
    V = 3
    E = 2
    src=[1,3]
    tgt=[2,2]
end

draw(w)

# The CSet API generalizes the traditional Graph API

parts(w, :V)  # vertex set

parts(w,:E) # edge set

w[:src] # source map

w[:tgt] # target map


incident(w, 1, :src) # edges out of vertex 1

incident(w, 2, :tgt) # edges into vertex 2

w[incident(w, 2, :tgt), :src] # vertices that are the source of edges whose target is vertex 2

w[incident(w, 1, :src), :tgt] # vertices that are the target of edges whose src is vertex 1


# ### Exercise:
# a. Use the @acset macro to make a graph with at least 5 vertices
# b. Draw the graph
# c. Compute in neighbors and out neighbors and make sure they match your expectations.
# d. Write a function that computes the 2-hop out-neighbors of a vertex.


## Graph Homomorphisms
# We can construct some graph homomorphisms between our two graphs.
# What data do we need to specify?

ϕ = ACSetTransformation(e,w,E=[1], V=[1,2])

is_natural(ϕ)

# The ACSetTransformation constructor does not automatically validate that the naturality squares commute!

ϕᵦ = ACSetTransformation(e,w,E=[1], V=[3,2])

is_natural(ϕᵦ)

# So how does Catlab store the data of the natural transformation? 

ϕ.dom

ϕ.codom

ϕ.components

# We can check the  naturality squares ourselves

# src ⋅ ϕᵥ == ϕₑ ⋅ src
ϕ[:V](dom(ϕ)[:,:src]) == codom(ϕ)[ϕ[:E].func, :src]
# tgt ⋅ ϕᵥ == ϕₑ ⋅ tgt
ϕ[:V](dom(ϕ)[:,:tgt]) == codom(ϕ)[ϕ[:E].func, :tgt]

# This approach generalizes to the following: 
#
# ```julia
# function is_natural(α::ACSetTransformation{S}) where {S}
#    X, Y = dom(α), codom(α)
#    for (f, c, d) in zip(hom(S), dom(S), codom(S))
#      Xf, Yf, α_c, α_d = subpart(X,f), subpart(Y,f), α[c], α[d]
#      all(Yf[α_c(i)] == α_d(Xf[i]) for i in eachindex(Xf)) || return false
#    end
#    return true
# end
# ```
#
# Notice how we iterate over the homs in the schema category S `(f, c, d) in zip(hom(S), dom(S), codom(S))` We get one universally quantified equation `all(Yf[α_c(i)] == α_d(Xf[i]) for i in eachindex(Xf))` for each morphism in the indexing category
# 
# ### Exercise:
# a. Take your graph from the previous exercise and construct a graph homomorphism from the wedge (w) into it.
# b. Check that the naturality equations are satisfied.
# c. Explain why we don't need to specify any data for the source and target morphisms in TheoryGraph when definining a graph homomorphism

# ## Finding Homomorphisms Automatically
# As you saw in the previous exercise, constructing a natural transformation can be quite tedious. We want computers to automate tedious things for us. So we use an algorithm to enumerate all the homomorphisms between two CSets.

# CSet homomorphisms f:A→B are ways of finding a part of B that is shaped like A. You can view this as pattern matching. The graph A is the pattern and the graph B is the data. A morphism f:A→B is a collection of vertices and edges in B that is shaped like A. Note that you can ask Catlab to enforce constraints on the homomorphisms it will find including computing monic (injective) morphisms by passing the keyword `monic=true`. A monic morphism into B is a subobject of B.  You can pass `iso=true` to get isomorphisms.

t = @acset Graphs.Graph begin
    V = 3
    E = 3
    src = [1,2,1]
    tgt = [2,3,3]
end

draw(t)

T = @acset Graphs.Graph begin
    V = 6
    E = 9
    src = [1,2,1, 3, 1,5,2,2,4]
    tgt = [2,3,3, 4, 4,6,5,6,6]
end

draw(T)

length(homomorphisms(t, T, monic=true))

map(homomorphisms(t,T)) do ϕ
    collect(ϕ[:V])
end

length(homomorphisms(T,t))

add_loops!(g) = add_parts!(g, :E, nparts(g,:V), src=parts(g,:V), tgt=parts(g,:V))
add_loops(g) = begin
    h = copy(g)
    add_loops!(h)
    return h
end

add_loops(t) |> draw

draw(add_loops(T))

length(homomorphisms(T,add_loops(t)))


# Bipartite Graphs

length(homomorphisms(e, T))

nparts(T, :E)

length(homomorphisms(T,e))

sq = apex(product(add_loops(e), add_loops(e)))
rem_parts!(sq, :E, [1,5,6,8,9])
draw(sq)

esym = @acset Graphs.Graph begin
    V = 2
    E = 2
    src = [1,2]
    tgt = [2,1]
end

draw(id(esym))

graphhoms(g,h) = begin
    map(homomorphisms(g,h)) do ϕ
        collect(ϕ[:V])
    end
end

# There are two ways to bipartition sq.
graphhoms(sq, esym)

# This comes from the fact that esym has 2 automorphisms!

graphhoms(esym, esym)

draw(homomorphisms(sq, esym)[1])

draw(homomorphisms(sq, esym)[2])

# We can generalize the notion of Bipartite graph to any number of parts.

clique(k::Int) = begin
    Kₖ = Graphs.Graph(k)
    for i in 1:k
        for j in 1:k
            if j ≠ i
                add_parts!(Kₖ, :E, 1, src=i, tgt=j)
            end
        end
    end
    return Kₖ
end

K₃ = clique(3)

draw(id(K₃))

draw(homomorphism(T, K₃))

# ### Exercise:
# a) Find a graph that is not 3-colorable
# b) Find a graph that is not 4-colorable


# ## Homomorphisms in [C, Set] are like Types
# Any graph can play the role of the codomain. If you pick a graph that is incomplete, you get a more constrained notion of coloring where there are color combinations that are forbidden.
triloop = @acset Graphs.Graph begin
    V = 3
    E = 3
    src = [1,2,3]
    tgt = [2,3,1]
end

graphhoms(triloop, triloop)

T2 = @acset Graphs.Graph begin
    V = 6
    E = 6
    src = [1,2,3,4,5,6]
    tgt = [2,3,1,5,6,4]
end

draw(T2)

graphhoms(triloop, T2)

T3 = @acset Graphs.Graph begin
    V = 6
    E = 7
    src = [1,2,3,4,5,6, 2]
    tgt = [2,3,1,5,6,4, 4]
end

draw(T3)

graphhoms(T3, triloop)

draw(id(triloop))

draw(homomorphisms(T3, triloop)[1])
