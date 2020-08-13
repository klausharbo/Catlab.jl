export RigCategory, SymmetricRigCategory, DistributiveMonoidalCategory,
  DistributiveSemiadditiveCategory, DistributiveCategory

# Distributive categories
#########################

""" Theory of a *rig category*, also known as a *bimonoidal category*

[Rig categories](https://ncatlab.org/nlab/show/rig+category) are the most
general in the hierarchy of [distributive monoidal
structures](https://ncatlab.org/nlab/show/distributivity+for+monoidal+structures).

TODO: Do we also want the distributivty and absorption isomorphisms? Usually we
ignore coherence isomorphisms such as associators and unitors.

FIXME: This theory should also inherit `MonoidalCategory`, but multiple
inheritance is not supported.
"""
@signature RigCategory{Ob,Hom} <: SymmetricMonoidalCategoryAdditive{Ob,Hom} begin
  otimes(A::Ob, B::Ob)::Ob
  otimes(f::(A → B), g::(C → D))::((A ⊗ C) → (B ⊗ D)) ⊣
    (A::Ob, B::Ob, C::Ob, D::Ob)
  @op (⊗) := otimes
  munit()::Ob
end

""" Theory of a *symmetric rig category*

FIXME: Should also inherit `SymmetricMonoidalCategory`.
"""
@signature SymmetricRigCategory{Ob,Hom} <: RigCategory{Ob,Hom} begin
  braid(A::Ob, B::Ob)::((A ⊗ B) → (B ⊗ A))
  @op (σ) := braid
end

""" Theory of a *distributive (symmetric) monoidal category*

Reference: Jay, 1992, LFCS tech report LFCS-92-205, "Tail recursion through
universal invariants", Section 3.2

FIXME: Should also inherit `CocartesianCategory`.
"""
@theory DistributiveMonoidalCategory{Ob,Hom} <: SymmetricRigCategory{Ob,Hom} begin
  plus(A::Ob)::((A ⊕ A) → A)
  zero(A::Ob)::(mzero() → A)
  
  copair(f::(A → C), g::(B → C))::((A ⊕ B) → C) <= (A::Ob, B::Ob, C::Ob)
  coproj1(A::Ob, B::Ob)::(A → (A ⊕ B))
  coproj2(A::Ob, B::Ob)::(B → (A ⊕ B))
  
  copair(f,g) == (f⊕g)⋅plus(C) ⊣ (A::Ob, B::Ob, C::Ob, f::(A → C), g::(B → C))
  coproj1(A,B) == id(A)⊕zero(B) ⊣ (A::Ob, B::Ob)
  coproj2(A,B) == zero(A)⊕id(B) ⊣ (A::Ob, B::Ob)
  
  # Naturality axioms.
  plus(A)⋅f == (f⊕f)⋅plus(B) ⊣ (A::Ob, B::Ob, f::(A → B))
  zero(A)⋅f == zero(B) ⊣ (A::Ob, B::Ob, f::(A → B))
end

""" Theory of a *distributive monoidal category with diagonals*

FIXME: Should also inherit `MonoidalCategoryWithDiagonals`.
"""
@theory DistributiveMonoidalCategoryWithDiagonals{Ob,Hom} <:
    DistributiveMonoidalCategory{Ob,Hom} begin
  mcopy(A::Ob)::(A → (A ⊗ A))
  @op (Δ) := mcopy
  delete(A::Ob)::(A → munit())
  @op (◊) := delete
end

""" Theory of a *distributive semiadditive category*

This terminology is not standard but the concept occurs frequently. A
distributive semiadditive category is a semiadditive category (or biproduct)
category, written additively, with a tensor product that distributes over the
biproduct.

FIXME: Should also inherit `SemiadditiveCategory`
"""
@theory DistributiveSemiadditiveCategory{Ob,Hom} <: DistributiveMonoidalCategory{Ob,Hom} begin
  mcopy(A::Ob)::(A → (A ⊕ A))
  @op (Δ) := mcopy
  delete(A::Ob)::(A → mzero())
  @op (◊) := delete

  pair(f::(A → B), g::(A → C))::(A → (B ⊕ C)) ⊣ (A::Ob, B::Ob, C::Ob)
  proj1(A::Ob, B::Ob)::((A ⊕ B) → A)
  proj2(A::Ob, B::Ob)::((A ⊕ B) → B)
  
  # Naturality axioms.
  f⋅Δ(B) == Δ(A)⋅(f⊕f) ⊣ (A::Ob, B::Ob, f::(A → B))
  f⋅◊(B) == ◊(A) ⊣ (A::Ob, B::Ob, f::(A → B))
end

""" Theory of a *distributive category*

A distributive category is a distributive monoidal category whose tensor product
is the cartesian product, see [`DistributiveMonoidalCategory`](@ref).

FIXME: Should also inherit `CartesianCategory`.
"""
@theory DistributiveCategory{Ob,Hom} <: DistributiveMonoidalCategoryWithDiagonals{Ob,Hom} begin
  pair(f::(A → B), g::(A → C))::(A → (B ⊗ C)) ⊣ (A::Ob, B::Ob, C::Ob)
  proj1(A::Ob, B::Ob)::((A ⊗ B) → A)
  proj2(A::Ob, B::Ob)::((A ⊗ B) → B)

  pair(f,g) == Δ(C)⋅(f⊗g) ⊣ (A::Ob, B::Ob, C::Ob, f::(C → A), g::(C → B))
  proj1(A,B) == id(A)⊗◊(B) ⊣ (A::Ob, B::Ob)
  proj2(A,B) == ◊(A)⊗id(B) ⊣ (A::Ob, B::Ob)
  
  # Naturality axioms.
  f⋅Δ(B) == Δ(A)⋅(f⊗f) ⊣ (A::Ob, B::Ob, f::(A → B))
  f⋅◊(B) == ◊(A) ⊣ (A::Ob, B::Ob, f::(A → B))
end
